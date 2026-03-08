import type { CaseFilters, CaseStatus, RiskLevel, ReturnReason } from '../types/index.ts';

interface Props {
    filters: CaseFilters;
    onChange: (f: CaseFilters) => void;
    caseCount: number;
    totalCount: number;
}

const STATUS_OPTIONS: { value: CaseStatus | 'all'; label: string }[] = [
    { value: 'all', label: 'All' },
    { value: 'created', label: 'Pending' },
    { value: 'executed', label: 'Resolved' },
    { value: 'denied', label: 'Denied' },
    { value: 'reviewing', label: 'Reviewing' },
    { value: 'exchange', label: 'Exchange' },
];

const RISK_OPTIONS: { value: RiskLevel | 'all'; label: string }[] = [
    { value: 'all', label: 'All' },
    { value: 'high', label: '🔴 High' },
    { value: 'medium', label: '🟡 Medium' },
    { value: 'low', label: '🟢 Low' },
];

const REASON_OPTIONS: { value: ReturnReason | 'all'; label: string }[] = [
    { value: 'all', label: 'All Reasons' },
    { value: 'damaged', label: 'Damaged' },
    { value: 'wrong_item', label: 'Wrong Item' },
    { value: 'not_as_described', label: 'Not as Described' },
    { value: 'defective', label: 'Defective' },
    { value: 'changed_mind', label: 'Changed Mind' },
    { value: 'too_large', label: 'Too Large' },
    { value: 'too_small', label: 'Too Small' },
];

const DATE_OPTIONS: { value: CaseFilters['dateRange']; label: string }[] = [
    { value: 'all', label: 'All Time' },
    { value: '7d', label: 'Last 7 days' },
    { value: '30d', label: 'Last 30 days' },
    { value: '90d', label: 'Last 90 days' },
];

export default function CaseFiltersSidebar({ filters, onChange, caseCount, totalCount }: Props) {
    const set = <K extends keyof CaseFilters>(key: K, val: CaseFilters[K]) =>
        onChange({ ...filters, [key]: val });

    return (
        <>
            {/* Search */}
            <div className="filters__section">
                <div className="filters__label">Search</div>
                <input
                    className="filters__search"
                    type="text"
                    placeholder="Case ID, customer, order…"
                    value={filters.search}
                    onChange={(e) => set('search', e.target.value)}
                />
            </div>

            {/* Count */}
            <div className="filters__section">
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--rc-text-primary)' }}>
                    {caseCount} case{caseCount !== 1 ? 's' : ''}
                    {caseCount !== totalCount && (
                        <span style={{ fontWeight: 400, color: 'var(--rc-text-tertiary)' }}> of {totalCount}</span>
                    )}
                </div>
            </div>

            {/* Status */}
            <div className="filters__section">
                <div className="filters__label">Status</div>
                <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                    {STATUS_OPTIONS.map((o) => (
                        <button
                            key={o.value}
                            className={`filter-chip ${filters.status === o.value ? 'filter-chip--active' : ''}`}
                            onClick={() => set('status', o.value)}
                        >
                            {o.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Risk */}
            <div className="filters__section">
                <div className="filters__label">Risk Level</div>
                <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                    {RISK_OPTIONS.map((o) => (
                        <button
                            key={o.value}
                            className={`filter-chip ${filters.riskLevel === o.value ? 'filter-chip--active' : ''}`}
                            onClick={() => set('riskLevel', o.value)}
                        >
                            {o.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Reason */}
            <div className="filters__section">
                <div className="filters__label">Return Reason</div>
                <select
                    className="filters__search"
                    value={filters.reason}
                    onChange={(e) => set('reason', e.target.value as CaseFilters['reason'])}
                >
                    {REASON_OPTIONS.map((o) => (
                        <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                </select>
            </div>

            {/* Date */}
            <div className="filters__section">
                <div className="filters__label">Date Range</div>
                <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                    {DATE_OPTIONS.map((o) => (
                        <button
                            key={o.value}
                            className={`filter-chip ${filters.dateRange === o.value ? 'filter-chip--active' : ''}`}
                            onClick={() => set('dateRange', o.value)}
                        >
                            {o.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Reset */}
            {(filters.search || filters.status !== 'all' || filters.riskLevel !== 'all' || filters.reason !== 'all' || filters.dateRange !== 'all') && (
                <button
                    className="action-btn action-btn--ghost"
                    onClick={() => onChange({ search: '', status: 'all', riskLevel: 'all', reason: 'all', dateRange: 'all' })}
                    style={{ fontSize: 12, color: 'var(--rc-danger)' }}
                >
                    ✕ Clear all filters
                </button>
            )}
        </>
    );
}
