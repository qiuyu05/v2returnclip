// GET /api/merchant/video — Get current demo video URL
// POST /api/merchant/video — Set demo video URL (merchant uploads on dashboard)

import { NextResponse } from 'next/server';
import { getDemoVideoUrl, setDemoVideoUrl } from '@/lib/supabase';
import { logger } from '@/lib/logger';

export async function GET() {
    const url = await getDemoVideoUrl();
    return NextResponse.json({ videoUrl: url });
}

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { videoUrl } = body as { videoUrl?: string };

        if (!videoUrl || typeof videoUrl !== 'string') {
            return NextResponse.json({ error: 'videoUrl is required' }, { status: 400 });
        }

        await setDemoVideoUrl(videoUrl);
        logger.info('Demo video URL set by merchant', { videoUrl });

        return NextResponse.json({ success: true, videoUrl });
    } catch (err) {
        logger.error('Failed to set video URL', { error: String(err) });
        return NextResponse.json({ error: 'Failed to save video URL' }, { status: 500 });
    }
}

export async function OPTIONS() {
    return new Response(null, { status: 204 });
}
