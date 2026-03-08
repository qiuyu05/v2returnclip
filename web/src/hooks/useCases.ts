import { useState, useEffect, useCallback, useMemo } from 'react';
import type { MerchantCase, CaseFilters, CasesApiResponse, RiskLevel, DashboardStats } from '../types/index.ts';

const BACKEND_URL: string = import.meta.env.VITE_BACKEND_URL ?? 'http://localhost:3001';

/** Assign a synthetic risk level based on case data */
function inferRisk(c: MerchantCase): RiskLevel {
    if (c.itemPrice > 200) return 'high';
    if (c.reason === 'damaged' || c.reason === 'defective') return 'medium';
    if (c.evidenceUrls.length === 0) return 'high';
    return 'low';
}

const DEFAULT_FILTERS: CaseFilters = {
    search: '',
    status: 'all',
    riskLevel: 'all',
    reason: 'all',
    dateRange: 'all',
};

export function useCases() {
    const [cases, setCases] = useState<MerchantCase[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [filters, setFilters] = useState<CaseFilters>(DEFAULT_FILTERS);
    const [selected, setSelected] = useState<MerchantCase | null>(null);

    const fetchCases = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const r = await fetch(`${BACKEND_URL}/api/cases`);
            if (!r.ok) throw new Error('Failed to fetch cases');
            const data: CasesApiResponse = await r.json();
            const enriched = (data.cases ?? []).map((c) => ({
                ...c,
                riskLevel: inferRisk(c),
                aiConfidence: 0.75 + Math.random() * 0.2, // simulated
            }));
            setCases(enriched);
            if (enriched.length > 0 && !selected) setSelected(enriched[0]);
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : 'Unknown error');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchCases();
    }, [fetchCases]);

    /** Optimistic update of a single case */
    const updateCase = useCallback((id: string, patch: Partial<MerchantCase>) => {
        setCases((prev) =>
            prev.map((c) => (c.id === id ? { ...c, ...patch } : c))
        );
        setSelected((prev) => (prev?.id === id ? { ...prev, ...patch } : prev));
    }, []);

    /** Filtered list */
    const filteredCases = useMemo(() => {
        return cases.filter((c) => {
            if (filters.status !== 'all' && c.status !== filters.status) return false;
            if (filters.riskLevel !== 'all' && c.riskLevel !== filters.riskLevel) return false;
            if (filters.reason !== 'all' && c.reason !== filters.reason) return false;
            if (filters.search) {
                const q = filters.search.toLowerCase();
                const match =
                    c.id.toLowerCase().includes(q) ||
                    c.orderNumber.toLowerCase().includes(q) ||
                    c.itemTitle.toLowerCase().includes(q) ||
                    (c.customerName?.toLowerCase().includes(q) ?? false);
                if (!match) return false;
            }
            if (filters.dateRange !== 'all') {
                const days = parseInt(filters.dateRange);
                const cutoff = Date.now() - days * 86_400_000;
                if (new Date(c.createdAt).getTime() < cutoff) return false;
            }
            return true;
        });
    }, [cases, filters]);

    /** Compute dashboard stats from all cases */
    const stats: DashboardStats = useMemo(() => {
        const total = cases.length;
        const resolved = cases.filter((c) => c.status === 'executed').length;
        const denied = cases.filter((c) => c.status === 'denied').length;
        const exchanges = cases.filter((c) => c.exchangeProductTitle).length;
        const pending = cases.filter((c) => c.status === 'created' || c.status === 'reviewing').length;
        const totalRevenue = cases.reduce((sum, c) => sum + c.itemPrice, 0);
        const highRisk = cases.filter((c) => c.riskLevel === 'high').length;
        return {
            totalReturns: total,
            aiAccuracy: total > 0 ? Math.round(((resolved + denied) / Math.max(total, 1)) * 100) : 0,
            avgProcessingTime: 28, // simulated seconds
            revenueSaved: Math.round(totalRevenue * 0.35),
            fraudPrevented: Math.round(highRisk * 89),
            exchangeRate: total > 0 ? Math.round((exchanges / total) * 100) : 0,
            pendingReview: pending,
        };
    }, [cases]);

    return {
        cases: filteredCases,
        allCases: cases,
        loading,
        error,
        selected,
        setSelected,
        filters,
        setFilters,
        updateCase,
        refresh: fetchCases,
        stats,
    };
}
