// Supabase REST client — no npm package needed, uses fetch directly
import type { Order } from '@/types';
import { logger } from './logger';

const SUPABASE_URL = process.env.SUPABASE_URL?.replace(/\/$/, '') || '';
const ANON_KEY = process.env.SUPABASE_ANON_KEY || '';

function hdrs(prefer?: string) {
    return {
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': prefer ?? 'return=representation',
    };
}

// Map backendCaseId → Supabase UUID (survives hot reload via global)
declare global {
    var __supabaseIdMap: Map<string, string> | undefined;
}
const supabaseIdMap = (global.__supabaseIdMap ??= new Map<string, string>());

// ── Order Lookup ──────────────────────────────────────────────────────────────

export async function lookupOrderFromSupabase(orderNumber: string): Promise<Order | null> {
    if (!SUPABASE_URL || !ANON_KEY) return null;
    try {
        const normalized = orderNumber.includes('#') ? orderNumber : `#RC-2026-${orderNumber}`;
        const url = `${SUPABASE_URL}/rest/v1/return_cases?order_number=eq.${encodeURIComponent(normalized)}&reason=eq.pending&select=order_data&limit=1`;
        const resp = await fetch(url, { headers: hdrs() });
        if (!resp.ok) return null;
        const rows = await resp.json() as { order_data: Order }[];
        if (!rows.length || !rows[0].order_data) return null;
        logger.info('Order found in Supabase', { orderNumber: normalized });
        return rows[0].order_data;
    } catch (err) {
        logger.error('Supabase order lookup error', { error: String(err) });
        return null;
    }
}

// ── Return Case ───────────────────────────────────────────────────────────────

export async function saveReturnCaseToSupabase(
    backendCaseId: string,
    orderId: string,
    itemId: string,
    reason: string,
    notes: string,
): Promise<void> {
    if (!SUPABASE_URL || !ANON_KEY) return;
    try {
        // Fetch the seed order data so we can store it alongside the active case
        const seedResp = await fetch(
            `${SUPABASE_URL}/rest/v1/return_cases?order_id=eq.${encodeURIComponent(orderId)}&reason=eq.pending&select=order_data&limit=1`,
            { headers: hdrs() },
        );
        const seedRows = seedResp.ok ? await seedResp.json() as { order_data: Order }[] : [];
        const orderData = seedRows[0]?.order_data ?? null;
        const lineItem = orderData?.lineItems?.find(li => li.id === itemId) ?? orderData?.lineItems?.[0];

        const resp = await fetch(`${SUPABASE_URL}/rest/v1/return_cases`, {
            method: 'POST',
            headers: hdrs(),
            body: JSON.stringify({
                order_id: backendCaseId,    // store backend ID here for evidence FK lookup
                order_number: orderId,
                item_id: itemId,
                reason,
                notes: notes || lineItem?.title || '',
                status: 'created',
                order_data: orderData,
            }),
        });

        if (!resp.ok) {
            logger.warn('Failed to save case to Supabase', { status: resp.status });
            return;
        }
        const rows = await resp.json() as { id: string }[];
        if (rows[0]?.id) {
            supabaseIdMap.set(backendCaseId, rows[0].id);
            logger.info('Saved return case to Supabase', { backendCaseId, supabaseId: rows[0].id });
        }
    } catch (err) {
        logger.error('Failed to save case to Supabase', { error: String(err) });
    }
}

// ── Evidence ──────────────────────────────────────────────────────────────────

export async function saveEvidenceToSupabase(backendCaseId: string, imageUrls: string[]): Promise<void> {
    if (!SUPABASE_URL || !ANON_KEY) return;

    let supabaseId = supabaseIdMap.get(backendCaseId);

    // Re-hydrate from Supabase if we lost the map (e.g. server restart)
    if (!supabaseId) {
        const resp = await fetch(
            `${SUPABASE_URL}/rest/v1/return_cases?order_id=eq.${encodeURIComponent(backendCaseId)}&select=id&limit=1`,
            { headers: hdrs() },
        );
        const rows = resp.ok ? await resp.json() as { id: string }[] : [];
        if (rows[0]?.id) {
            supabaseId = rows[0].id;
            supabaseIdMap.set(backendCaseId, supabaseId);
        }
    }

    if (!supabaseId) {
        logger.warn('No Supabase ID for evidence', { backendCaseId });
        return;
    }

    try {
        const records = imageUrls.map(url => ({
            case_id: supabaseId,
            cloudinary_public_id: extractPublicId(url),
            secure_url: url,
            type: 'photo',
        }));
        const resp = await fetch(`${SUPABASE_URL}/rest/v1/evidence_assets`, {
            method: 'POST',
            headers: hdrs('return=minimal'),
            body: JSON.stringify(records),
        });
        if (!resp.ok) {
            logger.warn('Failed to save evidence to Supabase', { status: resp.status });
        } else {
            logger.info('Saved evidence to Supabase', { backendCaseId, count: imageUrls.length });
        }
    } catch (err) {
        logger.error('Failed to save evidence to Supabase', { error: String(err) });
    }
}

function extractPublicId(url: string): string {
    const match = url.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.\w+)?$/);
    return match?.[1] ?? url;
}

// ── Execution ─────────────────────────────────────────────────────────────────

export async function saveExecutionToSupabase(
    backendCaseId: string,
    optionId: string,
    idempotencyKey: string,
    amount: number,
    exchangeInfo?: { productTitle: string; variantTitle: string; price: number } | null,
): Promise<void> {
    if (!SUPABASE_URL || !ANON_KEY) return;

    let supabaseId = supabaseIdMap.get(backendCaseId);
    if (!supabaseId) {
        const resp = await fetch(
            `${SUPABASE_URL}/rest/v1/return_cases?order_id=eq.${encodeURIComponent(backendCaseId)}&select=id&limit=1`,
            { headers: hdrs() },
        );
        const rows = resp.ok ? await resp.json() as { id: string }[] : [];
        if (rows[0]?.id) {
            supabaseId = rows[0].id;
            supabaseIdMap.set(backendCaseId, supabaseId);
        }
    }

    if (!supabaseId) {
        logger.warn('No Supabase ID for execution', { backendCaseId });
        return;
    }

    try {
        // Update case status
        await fetch(`${SUPABASE_URL}/rest/v1/return_cases?order_id=eq.${encodeURIComponent(backendCaseId)}`, {
            method: 'PATCH',
            headers: hdrs('return=minimal'),
            body: JSON.stringify({ status: 'executed', updated_at: new Date().toISOString() }),
        });

        // Insert execution record
        await fetch(`${SUPABASE_URL}/rest/v1/executions`, {
            method: 'POST',
            headers: hdrs('return=minimal'),
            body: JSON.stringify({
                case_id: supabaseId,
                selected_option_id: optionId,
                idempotency_key: idempotencyKey,
                status: 'completed',
                amount,
                currency: 'CAD',
                provider: exchangeInfo ? 'exchange' : 'refund',
                provider_response: exchangeInfo ?? null,
            }),
        });

        logger.info('Saved execution to Supabase', { backendCaseId, amount, exchangeInfo });
    } catch (err) {
        logger.error('Failed to save execution to Supabase', { error: String(err) });
    }
}

// ── Cases List ────────────────────────────────────────────────────────────────

export interface MerchantCase {
    id: string;
    supabaseId: string;
    orderNumber: string;
    itemTitle: string;
    itemPrice: number;
    itemImageUrl: string | null;
    status: string;
    reason: string;
    evidenceUrls: string[];
    exchangeProductTitle: string | null;
    exchangeVariantTitle: string | null;
    exchangePrice: number | null;
    createdAt: string;
}

export async function listActiveCasesFromSupabase(): Promise<MerchantCase[]> {
    if (!SUPABASE_URL || !ANON_KEY) return [];
    try {
        const url = `${SUPABASE_URL}/rest/v1/return_cases?reason=neq.pending&select=id,order_id,order_number,item_id,reason,status,order_data,created_at,evidence_assets(secure_url),executions(selected_option_id,amount,provider,provider_response)&order=created_at.desc&limit=50`;
        const resp = await fetch(url, { headers: hdrs() });
        if (!resp.ok) return [];

        type Row = {
            id: string;
            order_id: string;
            order_number: string;
            item_id: string;
            reason: string;
            status: string;
            order_data: Order | null;
            created_at: string;
            evidence_assets: { secure_url: string }[];
            executions: { selected_option_id: string; amount: number; provider: string; provider_response: { productTitle: string; variantTitle: string; price: number } | null }[];
        };

        const rows = await resp.json() as Row[];

        return rows.map(row => {
            const orderData = row.order_data;
            const lineItem = orderData?.lineItems?.find(li => li.id === row.item_id) ?? orderData?.lineItems?.[0];
            const exec = row.executions?.[0] ?? null;
            const exchangeInfo = exec?.provider === 'exchange' ? exec.provider_response : null;

            // Repopulate map in case of server restart
            if (row.order_id?.startsWith('case_') && row.id) {
                supabaseIdMap.set(row.order_id, row.id);
            }

            return {
                id: row.order_id ?? row.id,
                supabaseId: row.id,
                orderNumber: orderData?.orderNumber ?? row.order_number ?? '',
                itemTitle: lineItem?.title ?? row.item_id ?? 'Unknown Item',
                itemPrice: lineItem?.price ?? 0,
                itemImageUrl: lineItem?.imageUrl ?? null,
                status: row.status,
                reason: row.reason,
                evidenceUrls: (row.evidence_assets ?? []).map(e => e.secure_url),
                exchangeProductTitle: exchangeInfo?.productTitle ?? null,
                exchangeVariantTitle: exchangeInfo?.variantTitle ?? null,
                exchangePrice: exchangeInfo?.price ?? (exec?.provider === 'exchange' ? exec.amount : null),
                createdAt: row.created_at,
            };
        });
    } catch (err) {
        logger.error('Failed to list cases from Supabase', { error: String(err) });
        return [];
    }
}

// ── Demo Video ────────────────────────────────────────────────────────────────

export async function getDemoVideoUrl(): Promise<string | null> {
    if (!SUPABASE_URL || !ANON_KEY) return null;
    try {
        const url = `${SUPABASE_URL}/rest/v1/merchants?name=eq.Refined+Concept&select=policy&limit=1`;
        const resp = await fetch(url, { headers: hdrs() });
        if (!resp.ok) return null;
        const rows = await resp.json() as { policy: { demoVideoUrl?: string } }[];
        return rows[0]?.policy?.demoVideoUrl ?? null;
    } catch {
        return null;
    }
}

export async function setDemoVideoUrl(videoUrl: string): Promise<void> {
    if (!SUPABASE_URL || !ANON_KEY) return;
    try {
        const checkResp = await fetch(
            `${SUPABASE_URL}/rest/v1/merchants?name=eq.Refined+Concept&select=id&limit=1`,
            { headers: hdrs() },
        );
        const existing = checkResp.ok ? await checkResp.json() as { id: string }[] : [];

        if (existing.length > 0) {
            await fetch(`${SUPABASE_URL}/rest/v1/merchants?id=eq.${existing[0].id}`, {
                method: 'PATCH',
                headers: hdrs('return=minimal'),
                body: JSON.stringify({ policy: { demoVideoUrl: videoUrl } }),
            });
        } else {
            await fetch(`${SUPABASE_URL}/rest/v1/merchants`, {
                method: 'POST',
                headers: hdrs('return=minimal'),
                body: JSON.stringify({ name: 'Refined Concept', policy: { demoVideoUrl: videoUrl } }),
            });
        }
        logger.info('Demo video URL updated', { videoUrl });
    } catch (err) {
        logger.error('Failed to set demo video URL', { error: String(err) });
    }
}
