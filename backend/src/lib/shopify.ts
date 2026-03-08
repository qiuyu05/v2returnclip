// Shopify Admin API client (secrets stay on server)
// Phase C implementation — currently returns mock data

import { logger } from './logger';
import type { Order, ReturnPolicy } from '@/types';
import { getMockPolicy } from './db';
import { lookupOrderFromSupabase, getDemoVideoUrl } from './supabase';

const STORE_DOMAIN = process.env.SHOPIFY_STORE_DOMAIN || '';
const ADMIN_TOKEN = process.env.SHOPIFY_ADMIN_TOKEN || '';
const SHOPIFY_ENABLED = process.env.SHOPIFY_ENABLED === 'true';

export function isShopifyConfigured(): boolean {
    return SHOPIFY_ENABLED && Boolean(STORE_DOMAIN && ADMIN_TOKEN);
}

/**
 * Lookup order by order number and email.
 * Falls back to mock data if Shopify is not configured.
 */
export async function lookupOrder(
    orderNumber: string,
    email: string
): Promise<{ order: Order; policy: ReturnPolicy; eligible: boolean } | null> {
    const policy = getMockPolicy();

    // Inject demo video URL from Supabase merchants table
    const demoVideoUrl = await getDemoVideoUrl();
    if (demoVideoUrl) (policy as Record<string, unknown>).demoVideoUrl = demoVideoUrl;

    // 1. Check Supabase first — orders seeded here are the source of truth
    const supabaseOrder = await lookupOrderFromSupabase(orderNumber);
    if (supabaseOrder) {
        logger.info('Order served from Supabase', { orderNumber: supabaseOrder.orderNumber });
        return { order: supabaseOrder, policy, eligible: true };
    }

    // 2. Try Shopify Admin API if configured
    if (isShopifyConfigured()) {
        try {
            const searchName = orderNumber.replace('#', '').replace(/RC-\d{4}-/, '');
            const url = `https://${STORE_DOMAIN}/admin/api/2024-01/orders.json?name=${encodeURIComponent(searchName)}&status=any&limit=1`;

            const response = await fetch(url, {
                headers: {
                    'X-Shopify-Access-Token': ADMIN_TOKEN,
                    'Content-Type': 'application/json',
                },
            });

            if (response.ok) {
                const data = await response.json();
                const shopifyOrder = data.orders?.[0];

                if (shopifyOrder) {
                    if (email && shopifyOrder.email?.toLowerCase() !== email.toLowerCase()) {
                        logger.warn('Email mismatch for order', { orderNumber });
                        return null;
                    }

                    const order: Order = {
                        id: String(shopifyOrder.id),
                        orderNumber: shopifyOrder.name || orderNumber,
                        purchaseDate: shopifyOrder.created_at,
                        purchaseLocation: shopifyOrder.billing_address?.city
                            ? `${shopifyOrder.billing_address.city}, ${shopifyOrder.billing_address.province_code}`
                            : 'Online',
                        customerEmail: shopifyOrder.email || '',
                        customerName: `${shopifyOrder.customer?.first_name || ''} ${shopifyOrder.customer?.last_name || ''}`.trim(),
                        lineItems: (shopifyOrder.line_items || []).map((li: Record<string, unknown>) => ({
                            id: String(li.id),
                            productId: String(li.product_id),
                            variantId: String(li.variant_id),
                            title: String(li.title || ''),
                            variantTitle: li.variant_title ? String(li.variant_title) : undefined,
                            sku: String(li.sku || ''),
                            quantity: Number(li.quantity) || 1,
                            price: parseFloat(String(li.price)) || 0,
                            imageUrl: undefined,
                        })),
                        totalPrice: parseFloat(shopifyOrder.total_price) || 0,
                        currency: shopifyOrder.currency || 'CAD',
                        paymentMethod: {
                            type: 'card',
                            lastFour: shopifyOrder.payment_gateway_names?.[0]?.slice(-4),
                            brand: shopifyOrder.payment_gateway_names?.[0],
                        },
                    };

                    return { order, policy, eligible: true };
                }
            }
        } catch (err) {
            logger.error('Shopify lookup failed', { error: String(err) });
        }
    }

    logger.warn('Order not found in Supabase or Shopify', { orderNumber });
    return null;
}

/**
 * Execute a refund on Shopify.
 * Returns true if successful.
 */
export async function executeRefund(
    orderId: string,
    amount: number,
    _currency: string = 'CAD'
): Promise<{ success: boolean; message: string }> {
    if (!isShopifyConfigured()) {
        logger.info('Shopify not configured, simulating refund', { orderId, amount });
        return { success: true, message: 'Refund simulated (Shopify not configured)' };
    }

    try {
        const url = `https://${STORE_DOMAIN}/admin/api/2024-01/orders/${orderId}/refunds.json`;
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'X-Shopify-Access-Token': ADMIN_TOKEN,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                refund: {
                    note: 'Refund via ReturnClip',
                    notify: true,
                    transactions: [
                        {
                            kind: 'refund',
                            amount: amount.toFixed(2),
                        },
                    ],
                },
            }),
        });

        if (!response.ok) {
            const errorData = await response.text();
            logger.error('Shopify refund error', { status: response.status, body: errorData });
            return { success: false, message: `Shopify refund failed: ${response.status}` };
        }

        logger.info('Shopify refund successful', { orderId, amount });
        return { success: true, message: 'Refund processed via Shopify' };
    } catch (err) {
        logger.error('Shopify refund exception', { error: String(err) });
        return { success: false, message: String(err) };
    }
}
