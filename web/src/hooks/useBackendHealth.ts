import { useState, useEffect, useCallback } from 'react';

const BACKEND_URL: string = import.meta.env.VITE_BACKEND_URL ?? 'http://localhost:3001';
const POLL_INTERVAL = 30_000; // 30 seconds

export function useBackendHealth() {
    const [online, setOnline] = useState<boolean | null>(null);
    const [lastChecked, setLastChecked] = useState<Date | null>(null);

    const check = useCallback(async () => {
        try {
            const r = await fetch(`${BACKEND_URL}/api/health`, { signal: AbortSignal.timeout(5000) });
            const d = r.ok ? await r.json() : null;
            setOnline(!!d?.status);
        } catch {
            setOnline(false);
        }
        setLastChecked(new Date());
    }, []);

    useEffect(() => {
        check();
        const id = setInterval(check, POLL_INTERVAL);
        return () => clearInterval(id);
    }, [check]);

    return { online, lastChecked, refresh: check };
}
