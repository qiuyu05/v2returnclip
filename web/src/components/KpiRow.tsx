import type { DashboardStats } from '../types/index.ts';

interface Props {
    stats: DashboardStats;
    loading: boolean;
}

interface KpiDef {
    key: keyof DashboardStats;
    label: string;
    icon: string;
    iconBg: string;
    format: (v: number) => string;
    change: (v: number) => string;
    positive: boolean;
}

const KPI_DEFS: KpiDef[] = [
    {
        key: 'totalReturns',
        label: 'Total Returns',
        icon: '📦',
        iconBg: '#eef2ff',
        format: (v) => String(v),
        change: () => '+23 this week',
        positive: true,
    },
    {
        key: 'revenueSaved',
        label: 'Revenue Recovered',
        icon: '💰',
        iconBg: '#d1fae5',
        format: (v) => `$${(v / 1000).toFixed(1)}K`,
        change: () => '+$1.2K this week',
        positive: true,
    },
    {
        key: 'fraudPrevented',
        label: 'Fraud Prevented',
        icon: '🛡️',
        iconBg: '#fee2e2',
        format: (v) => `$${v.toLocaleString()}`,
        change: () => '3 flagged this week',
        positive: true,
    },
    {
        key: 'exchangeRate',
        label: 'Exchange Uptake',
        icon: '🔄',
        iconBg: '#fef3c7',
        format: (v) => `${v}%`,
        change: (v) => (v > 20 ? 'Above target' : 'Below target'),
        positive: true,
    },
    {
        key: 'pendingReview',
        label: 'Pending Review',
        icon: '⏳',
        iconBg: '#e0e7ff',
        format: (v) => String(v),
        change: (v) => (v > 0 ? 'Needs attention' : 'All clear'),
        positive: false,
    },
];

export default function KpiRow({ stats, loading }: Props) {
    if (loading) {
        return (
            <div className="kpi-row">
                {Array.from({ length: 5 }).map((_, i) => (
                    <div key={i} className="skeleton skeleton--kpi" />
                ))}
            </div>
        );
    }

    return (
        <div className="kpi-row">
            {KPI_DEFS.map((kpi) => {
                const val = stats[kpi.key];
                return (
                    <div key={kpi.key} className="kpi-card">
                        <div className="kpi-card__icon" style={{ background: kpi.iconBg }}>
                            {kpi.icon}
                        </div>
                        <div className="kpi-card__value">{kpi.format(val)}</div>
                        <div className="kpi-card__label">{kpi.label}</div>
                        <div className={`kpi-card__change ${kpi.positive ? 'kpi-card__change--up' : 'kpi-card__change--down'}`}>
                            {kpi.positive ? '↑' : '↓'} {kpi.change(val)}
                        </div>
                    </div>
                );
            })}
        </div>
    );
}
