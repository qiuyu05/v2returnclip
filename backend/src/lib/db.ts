// Mock data store (replaces DB in Phase D)
// All data is in-memory — resets on restart

import type { ReturnCase, Order, ReturnPolicy, ConditionAssessment, RefundDecision } from '@/types';

// Store Maps on global to survive Next.js hot-reload module isolation in dev mode
declare global {
    var __returnCases: Map<string, ReturnCase> | undefined;
    var __evidenceAssets: Map<string, string[]> | undefined;
    var __assessments: Map<string, ConditionAssessment> | undefined;
    var __decisions: Map<string, RefundDecision> | undefined;
    var __executions: Map<string, { optionId: string; idempotencyKey: string; status: string }> | undefined;
}

const returnCases = (global.__returnCases ??= new Map<string, ReturnCase>());
const evidenceAssets = (global.__evidenceAssets ??= new Map<string, string[]>());
const assessments = (global.__assessments ??= new Map<string, ConditionAssessment>());
const decisions = (global.__decisions ??= new Map<string, RefundDecision>());
const executions = (global.__executions ??= new Map<string, { optionId: string; idempotencyKey: string; status: string }>());

// -- Return Cases --

export function createCase(data: {
    orderId: string;
    itemId: string;
    reason: string;
    notes?: string;
}): ReturnCase {
    const id = `case_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    const now = new Date().toISOString();
    const returnCase: ReturnCase = {
        id,
        merchantId: 'refined_concept',
        orderId: data.orderId,
        itemId: data.itemId,
        reason: data.reason,
        notes: data.notes,
        status: 'created',
        createdAt: now,
        updatedAt: now,
    };
    returnCases.set(id, returnCase);
    return returnCase;
}

export function getCase(caseId: string): ReturnCase | undefined {
    return returnCases.get(caseId);
}

export function listCases(): ReturnCase[] {
    return Array.from(returnCases.values()).sort((a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
}

export function updateCaseStatus(caseId: string, status: ReturnCase['status']): void {
    const c = returnCases.get(caseId);
    if (c) {
        c.status = status;
        c.updatedAt = new Date().toISOString();
    }
}

// -- Evidence --

export function addEvidence(caseId: string, imageUrls: string[]): void {
    const existing = evidenceAssets.get(caseId) || [];
    evidenceAssets.set(caseId, [...existing, ...imageUrls]);
    updateCaseStatus(caseId, 'evidence');
}

export function getEvidence(caseId: string): string[] {
    return evidenceAssets.get(caseId) || [];
}

// -- Assessments --

export function saveAssessment(caseId: string, assessment: ConditionAssessment): void {
    assessments.set(caseId, assessment);
    const c = returnCases.get(caseId);
    if (c) {
        c.assessment = assessment;
        c.status = 'assessed';
        c.updatedAt = new Date().toISOString();
    }
}

export function getAssessment(caseId: string): ConditionAssessment | undefined {
    return assessments.get(caseId);
}

// -- Decisions --

export function saveDecision(caseId: string, decision: RefundDecision): void {
    decisions.set(caseId, decision);
    const c = returnCases.get(caseId);
    if (c) {
        c.decision = decision;
        c.status = 'decided';
        c.updatedAt = new Date().toISOString();
    }
}

export function getDecision(caseId: string): RefundDecision | undefined {
    return decisions.get(caseId);
}

// -- Executions --

export function executeCase(
    caseId: string,
    optionId: string,
    idempotencyKey: string
): { executionId: string; status: string; isDuplicate: boolean } {
    // Check idempotency
    for (const [, exec] of executions) {
        if (exec.idempotencyKey === idempotencyKey) {
            return { executionId: idempotencyKey, status: exec.status, isDuplicate: true };
        }
    }

    const executionId = `exec_${Date.now().toString(36)}`;
    executions.set(executionId, { optionId, idempotencyKey, status: 'completed' });
    updateCaseStatus(caseId, 'executed');

    return { executionId, status: 'completed', isDuplicate: false };
}

// -- Mock Order Data (mirrors Swift MockData.swift) --

export function getMockOrder(orderId: string): Order | null {
    const orders: Record<string, Order> = {
        '12345': sampleOrder,
        'order_12345': sampleOrder,
        '67890': furnitureOrder,
        'order_67890': furnitureOrder,
        '99999': premiumOrder,
        'order_99999': premiumOrder,
    };
    return orders[orderId] || sampleOrder;
}

export function getMockPolicy(): ReturnPolicy {
    return furnitureReturnPolicy;
}

const sampleOrder: Order = {
    id: 'order_12345',
    orderNumber: '#RC-2026-12345',
    purchaseDate: new Date(Date.now() - 5 * 86400000).toISOString(),
    purchaseLocation: 'Toronto, ON',
    customerEmail: 'alex.johnson@returnclip-demo.com',
    customerName: 'Alex Johnson (Live)',
    lineItems: [
        {
            id: 'item_001',
            productId: 'prod_velvet_chair',
            variantId: 'var_navy',
            title: 'Velvet Accent Chair',
            variantTitle: 'Navy Blue',
            sku: 'CHAIR-VLV-NAVY-001',
            quantity: 1,
            price: 299.0,
            imageUrl: 'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?w=400',
            packagingVideoUrl: 'https://res.cloudinary.com/demo/video/upload/q_auto,f_auto/docs/cld-sample-video.mp4',
        },
    ],
    totalPrice: 299.0,
    currency: 'CAD',
    paymentMethod: { type: 'card', lastFour: '4242', brand: 'Visa' },
};

const furnitureOrder: Order = {
    id: 'order_67890',
    orderNumber: '#RC-2026-67890',
    purchaseDate: new Date(Date.now() - 12 * 86400000).toISOString(),
    purchaseLocation: 'Vancouver, BC',
    customerEmail: 'furniture.lover@example.com',
    customerName: 'Sam Chen',
    lineItems: [
        {
            id: 'item_003',
            productId: 'prod_sectional',
            variantId: 'var_gray',
            title: 'Milano Sectional Sofa',
            variantTitle: 'Charcoal Gray - Left Facing',
            sku: 'SOFA-MIL-GRY-L',
            quantity: 1,
            price: 1899.0,
            imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',
            packagingVideoUrl: 'https://res.cloudinary.com/demo/video/upload/q_auto,f_auto/docs/cld-sample-video.mp4',
        },
    ],
    totalPrice: 1899.0,
    currency: 'CAD',
    paymentMethod: { type: 'applePay' },
};

const premiumOrder: Order = {
    id: 'order_99999',
    orderNumber: '#RC-2026-99999',
    purchaseDate: new Date(Date.now() - 3 * 86400000).toISOString(),
    purchaseLocation: 'Toronto, ON',
    customerEmail: 'alex.johnson@returnclip-demo.com',
    customerName: 'Alex Johnson (Live)',
    lineItems: [
        {
            id: 'item_005',
            productId: 'prod_vanguard_lounger',
            variantId: 'var_leather_black',
            title: 'Vanguard Lounger — Full Suite',
            variantTitle: 'Obsidian Black / Leather',
            sku: 'VLNG-OBK-LTHR-001',
            quantity: 1,
            price: 5000.0,
            imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',
            packagingVideoUrl: 'https://res.cloudinary.com/demo/video/upload/q_auto,f_auto/docs/cld-sample-video.mp4',
        },
    ],
    totalPrice: 5000.0,
    currency: 'CAD',
    paymentMethod: { type: 'card', lastFour: '9999', brand: 'Amex' },
};

const furnitureReturnPolicy: ReturnPolicy = {
    id: 'policy_furniture',
    merchantName: 'Refined Concept',
    returnWindowDays: 30,
    conditionRequirements: [
        { category: 'damage', maxAllowedScore: 10, description: 'No scratches, dents, or tears' },
        { category: 'wear', maxAllowedScore: 15, description: 'Minimal signs of use' },
        { category: 'cleanliness', maxAllowedScore: 5, description: 'No stains or odors' },
        { category: 'completeness', maxAllowedScore: 0, description: 'All parts and hardware included' },
    ],
    restockingFeeThreshold: 85,
    restockingFeePercent: 20,
    allowExchange: true,
    allowStoreCredit: true,
    storeCreditBonus: 0.1,
    requiresPhotos: true,
    requiresVideo: false,
    demoVideoUrl: 'https://example.com/return-demo.mp4',
    shippingPaidBy: 'merchant',
    processingDays: 5,
};
