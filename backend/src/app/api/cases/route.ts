// GET /api/cases — List all return cases (for merchant dashboard)
import { NextResponse } from 'next/server';
import { listCases } from '@/lib/db';

export async function GET() {
    const cases = listCases();
    return NextResponse.json({ cases, total: cases.length });
}
