// POST /api/returns/create — Create a new return case

import { z } from 'zod';
import { createCase } from '@/lib/db';
import { handleRouteError } from '@/lib/errors';
import { logger } from '@/lib/logger';
import { saveReturnCaseToSupabase } from '@/lib/supabase';

const schema = z.object({
    orderId: z.string().min(1),
    itemId: z.string().min(1),
    reason: z.string().min(1),
    notes: z.string().default(''),
});

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const parsed = schema.safeParse(body);

        if (!parsed.success) {
            return Response.json({ error: 'Invalid request', issues: parsed.error.issues }, { status: 400 });
        }

        const returnCase = createCase(parsed.data);
        logger.info('Return case created', { caseId: returnCase.id, orderId: parsed.data.orderId });

        // Persist to Supabase (non-blocking)
        saveReturnCaseToSupabase(
            returnCase.id,
            parsed.data.orderId,
            parsed.data.itemId,
            parsed.data.reason,
            parsed.data.notes,
        ).catch(err => logger.error('Supabase case save failed', { error: String(err) }));

        return Response.json({
            caseId: returnCase.id,
            status: returnCase.status,
        });
    } catch (err) {
        return handleRouteError(err);
    }
}
