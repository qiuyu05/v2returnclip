// GET /api/cases — List all return cases (for merchant dashboard)
import { NextResponse } from 'next/server';
import { listActiveCasesFromSupabase } from '@/lib/supabase';

export async function GET() {
    const cases = await listActiveCasesFromSupabase();
    return NextResponse.json({ cases, total: cases.length });
}
