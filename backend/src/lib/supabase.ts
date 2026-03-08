// Supabase REST client — no npm package needed, uses fetch directly
import type { Order, ReturnPolicy } from '@/types';
import { logger } from './logger';

const SUPABASE_URL = process.env.SUPABASE_URL?.replace(/\/$/, '') || '';
const ANON_KEY = process.env.SUPABASE_ANON_KEY || '';

function headers() {
    return {
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`,
        'Content-Type': 'application/json',
    };
}

/**
 * Look up an order by order number from Supabase return_cases.order_data.
 * Returns the stored Order object, or null if not found.
 */
export async function lookupOrderFromSupabase(orderNumber: string): Promise<Order | null> {
    if (!SUPABASE_URL || !ANON_KEY) return null;

    try {
        // Normalize: accept "12345" or "#RC-2026-12345"
        const normalized = orderNumber.includes('#') ? orderNumber : `#RC-2026-${orderNumber}`;

        const url = `${SUPABASE_URL}/rest/v1/return_cases?order_number=eq.${encodeURIComponent(normalized)}&select=order_data&limit=1&status=eq.created`;
        const response = await fetch(url, { headers: headers() });

        if (!response.ok) {
            logger.warn('Supabase order lookup failed', { status: response.status });
            return null;
        }

        const rows = await response.json() as { order_data: Order }[];
        if (!rows.length || !rows[0].order_data) return null;

        logger.info('Order found in Supabase', { orderNumber: normalized });
        return rows[0].order_data;
    } catch (err) {
        logger.error('Supabase lookup error', { error: String(err) });
        return null;
    }
}
