// Server-side Gemini client (API key stays on server)

import { logger } from './logger';
import type { ConditionAssessment, RefundDecision, Order, LineItem, ReturnPolicy } from '@/types';

const API_KEY = process.env.GEMINI_API_KEY || '';
const BASE_URL = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

export function isGeminiConfigured(): boolean {
    return Boolean(API_KEY);
}

// Download an image URL and return it as a Gemini inline base64 part
async function fetchImagePart(url: string): Promise<{ inlineData: { mimeType: string; data: string } } | null> {
    try {
        const resp = await fetch(url, { signal: AbortSignal.timeout(8000) });
        if (!resp.ok) return null;
        const mimeType = (resp.headers.get('content-type') || 'image/jpeg').split(';')[0].trim();
        const buffer = await resp.arrayBuffer();
        const data = Buffer.from(buffer).toString('base64');
        return { inlineData: { mimeType, data } };
    } catch (err) {
        logger.warn('Failed to fetch image for Gemini', { url, error: String(err) });
        return null;
    }
}

/**
 * Analyze item condition from image URLs using Gemini Vision.
 * Images are downloaded server-side and sent as inline base64 so Gemini can actually see them.
 */
export async function analyzeCondition(imageUrls: string[]): Promise<ConditionAssessment> {
    if (!isGeminiConfigured()) {
        logger.warn('Gemini not configured, returning mock assessment');
        return mockAssessment();
    }

    // Download all images in parallel
    const imageParts = (await Promise.all(imageUrls.map(fetchImagePart))).filter(Boolean);

    if (imageParts.length === 0) {
        logger.warn('No images could be fetched for Gemini analysis');
        return mockAssessment();
    }

    const prompt = `You are a product return condition inspector. Examine these ${imageParts.length} evidence photo(s) carefully.

Rate each category from 0-100 (100 = perfect/new condition):
- damage: Physical damage (scratches, dents, tears, broken parts)
- wear: Signs of use or aging
- cleanliness: Stains, dirt, odors
- completeness: All parts/accessories present

Also list any specific issues you detect (e.g. "torn fabric", "missing leg", "water stain").

Respond ONLY with valid JSON — no markdown, no explanation:
{
  "overallQualityScore": <0-100>,
  "categoryScores": [
    {"category": "damage", "score": <0-100>, "notes": "<what you see>"},
    {"category": "wear", "score": <0-100>, "notes": "<what you see>"},
    {"category": "cleanliness", "score": <0-100>, "notes": "<what you see>"},
    {"category": "completeness", "score": <0-100>, "notes": "<what you see>"}
  ],
  "issues": ["<issue1>", "<issue2>"],
  "confidence": <0.0-1.0>,
  "reasonSummary": "<1-2 sentence plain-English summary of the item's condition>"
}`;

    try {
        const response = await fetch(`${BASE_URL}?key=${API_KEY}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{
                    parts: [
                        ...imageParts,   // real images first
                        { text: prompt },
                    ],
                }],
                generationConfig: { temperature: 0.1 },
            }),
        });

        if (!response.ok) {
            const errText = await response.text();
            logger.error('Gemini Vision API error', { status: response.status, body: errText });
            return mockAssessment();
        }

        const data = await response.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) {
            logger.error('Gemini returned no text', {
                finishReason: data?.candidates?.[0]?.finishReason,
                safetyRatings: data?.candidates?.[0]?.safetyRatings,
                rawResponse: JSON.stringify(data).slice(0, 500),
            });
            return mockAssessment();
        }

        let parsed: Record<string, unknown>;
        try {
            parsed = JSON.parse(text);
        } catch (parseErr) {
            logger.error('Gemini returned invalid JSON', { rawText: text.slice(0, 500), error: String(parseErr) });
            return mockAssessment();
        }

        logger.info('Gemini Vision analysis complete', {
            score: parsed.overallQualityScore,
            confidence: parsed.confidence,
            imageCount: imageParts.length,
        });

        return {
            ...parsed,
            analysisTimestamp: new Date().toISOString(),
        } as ConditionAssessment;
    } catch (err) {
        logger.error('Gemini Vision analysis failed', { error: String(err), stack: err instanceof Error ? err.stack : undefined });
        return mockAssessment();
    }
}

/**
 * Get refund decision based on assessment + policy using Gemini
 */
export async function getRefundDecision(
    order: Order,
    item: LineItem,
    reason: string,
    policy: ReturnPolicy,
    assessment: ConditionAssessment
): Promise<RefundDecision> {
    if (!isGeminiConfigured()) {
        logger.warn('Gemini not configured, returning mock decision');
        return mockDecision(item.price);
    }

    try {
        const daysSincePurchase = Math.floor(
            (Date.now() - new Date(order.purchaseDate).getTime()) / (1000 * 60 * 60 * 24)
        );

        const prompt = `You are a return policy enforcement AI. Analyze this return request.

ORDER: ${order.orderNumber}, Item: ${item.title} ($${item.price}), ${daysSincePurchase} days ago
REASON: ${reason}
POLICY: ${policy.merchantName}, ${policy.returnWindowDays}-day window, restocking fee ${policy.restockingFeePercent}% if quality < ${policy.restockingFeeThreshold}
CONDITION: Overall ${assessment.overallQualityScore}/100, confidence: ${assessment.confidence}

Respond with JSON:
{
  "decision": "full_refund"|"partial_refund"|"exchange_only"|"store_credit_only"|"denied",
  "refundAmount": <number>,
  "originalAmount": ${item.price},
  "restockingFee": <number|null>,
  "explanation": "<clear explanation>",
  "policyViolations": [],
  "alternativeOptions": [
    {"id": "<id>", "type": "refund_to_original"|"store_credit"|"exchange"|"partial_refund", "amount": <number>, "bonusAmount": <number|null>, "description": "<desc>"}
  ]
}`;

        const response = await fetch(`${BASE_URL}?key=${API_KEY}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: { temperature: 0.2 },
            }),
        });

        if (!response.ok) {
            logger.error('Gemini decision error', { status: response.status });
            return mockDecision(item.price);
        }

        const data = await response.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) return mockDecision(item.price);

        return JSON.parse(text);
    } catch (err) {
        logger.error('Gemini decision failed', { error: String(err) });
        return mockDecision(item.price);
    }
}

// -- Mock data for when Gemini is not configured --

function mockAssessment(): ConditionAssessment {
    return {
        overallQualityScore: 95,
        categoryScores: [
            { category: 'damage', score: 98, notes: 'No visible damage' },
            { category: 'wear', score: 95, notes: 'Appears unused' },
            { category: 'cleanliness', score: 97, notes: 'Clean condition' },
            { category: 'completeness', score: 100, notes: 'All items present' },
        ],
        issues: [],
        confidence: 0.94,
        analysisTimestamp: new Date().toISOString(),
    };
}

function mockDecision(price: number): RefundDecision {
    return {
        decision: 'full_refund',
        refundAmount: price,
        originalAmount: price,
        explanation: 'Item is in excellent condition within the return window. Full refund approved.',
        policyViolations: [],
        alternativeOptions: [
            { id: 'opt_1', type: 'refund_to_original', amount: price, description: 'Full refund to original payment method' },
            { id: 'opt_2', type: 'store_credit', amount: price, bonusAmount: price * 0.1, description: `Store credit with 10% bonus ($${(price * 1.1).toFixed(2)} total)` },
            { id: 'opt_3', type: 'exchange', amount: price, description: 'Exchange for different color/size' },
        ],
    };
}
