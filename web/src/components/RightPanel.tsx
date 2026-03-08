import type { MerchantCase, DashboardStats } from '../types/index.ts';

interface Props {
    case_: MerchantCase | null;
    stats: DashboardStats;
    allCases: MerchantCase[];
}

export default function RightPanel({ case_: c, stats, allCases }: Props) {
    const reviewQueue = allCases.filter((x) => x.status === 'created' || x.status === 'reviewing');
    const highRisk = allCases.filter((x) => x.riskLevel === 'high');

    return (
        <>
            {/* AI Decision Summary */}
            {c && (
                <div className="ai-panel">
                    <div className="ai-panel__header">
                        <span>🤖</span> AI Analysis
                    </div>
                    <div className="ai-panel__summary">
                        <div style={{ fontSize: 'var(--text-sm)', color: 'var(--rc-text-secondary)', marginBottom: 8 }}>
                            Confidence Score
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                            <div style={{
                                flex: 1, height: 8, background: 'var(--rc-border-light)', borderRadius: 4, overflow: 'hidden',
                            }}>
                                <div style={{
                                    height: '100%', borderRadius: 4,
                                    width: `${(c.aiConfidence ?? 0.85) * 100}%`,
                                    background: (c.aiConfidence ?? 0.85) > 0.8 ? 'var(--rc-success)' : 'var(--rc-warning)',
                                    transition: 'width 0.5s var(--ease-out)',
                                }} />
                            </div>
                            <span style={{ fontSize: 'var(--text-sm)', fontWeight: 700 }}>
                                {Math.round((c.aiConfidence ?? 0.85) * 100)}%
                            </span>
                        </div>
                        <div style={{ fontSize: 'var(--text-sm)', color: 'var(--rc-text-secondary)', lineHeight: 1.6 }}>
                            Gemini Vision analyzed {c.evidenceUrls.length} photo{c.evidenceUrls.length !== 1 ? 's' : ''}.
                            {c.riskLevel === 'high' && ' ⚠️ High-risk indicators detected.'}
                            {c.riskLevel === 'low' && ' Evidence appears consistent with claim.'}
                            {c.riskLevel === 'medium' && ' Some inconsistencies noted.'}
                        </div>
                    </div>

                    {/* Risk Flags */}
                    {c.riskLevel && c.riskLevel !== 'low' && (
                        <div>
                            <div className="section-header">Risk Flags</div>
                            {c.riskLevel === 'high' && (
                                <>
                                    <div className="risk-flag risk-flag--high">
                                        <span>🔴</span> Item value exceeds $200 threshold
                                    </div>
                                    {c.evidenceUrls.length === 0 && (
                                        <div className="risk-flag risk-flag--high">
                                            <span>🔴</span> No evidence photos submitted
                                        </div>
                                    )}
                                </>
                            )}
                            {c.riskLevel === 'medium' && (
                                <div className="risk-flag risk-flag--medium">
                                    <span>🟡</span> Damage/defect claim — verify evidence
                                </div>
                            )}
                        </div>
                    )}
                </div>
            )}

            {/* Merchant Modules */}
            <div className="section-header" style={{ marginTop: 'var(--sp-5)' }}>Merchant Insights</div>

            <div className="module-card">
                <div className="module-card__header">
                    <div className="module-card__title">💰 Revenue Recovery</div>
                </div>
                <div className="module-card__value" style={{ color: 'var(--rc-success)' }}>
                    ${(stats.revenueSaved / 1000).toFixed(1)}K
                </div>
                <div className="module-card__desc">From exchanges & partial refunds this month</div>
            </div>

            <div className="module-card">
                <div className="module-card__header">
                    <div className="module-card__title">🛡️ Fraud Prevented</div>
                </div>
                <div className="module-card__value" style={{ color: 'var(--rc-danger)' }}>
                    ${stats.fraudPrevented.toLocaleString()}
                </div>
                <div className="module-card__desc">{highRisk.length} high-risk cases flagged by AI</div>
            </div>

            <div className="module-card">
                <div className="module-card__header">
                    <div className="module-card__title">🔄 Exchange Uptake</div>
                </div>
                <div className="module-card__value" style={{ color: 'var(--rc-indigo)' }}>
                    {stats.exchangeRate}%
                </div>
                <div className="module-card__desc">Customers choosing exchanges over refunds</div>
            </div>

            <div className="module-card">
                <div className="module-card__header">
                    <div className="module-card__title">⚡ Avg Resolution</div>
                </div>
                <div className="module-card__value" style={{ color: 'var(--rc-text-primary)' }}>
                    {stats.avgProcessingTime}s
                </div>
                <div className="module-card__desc">Powered by Gemini Vision analysis</div>
            </div>

            {/* Manual Review Queue */}
            {reviewQueue.length > 0 && (
                <div className="module-card" style={{ borderColor: 'var(--rc-warning)', background: '#fffbeb' }}>
                    <div className="module-card__header">
                        <div className="module-card__title">⏳ Review Queue</div>
                        <span className="badge badge--review">{reviewQueue.length}</span>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginTop: 8 }}>
                        {reviewQueue.slice(0, 3).map((q) => (
                            <div key={q.id} style={{
                                fontSize: 'var(--text-xs)', color: 'var(--rc-text-secondary)',
                                display: 'flex', justifyContent: 'space-between',
                            }}>
                                <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 160 }}>
                                    {q.itemTitle}
                                </span>
                                <span style={{ fontWeight: 600, color: 'var(--rc-warning-text)' }}>
                                    ${q.itemPrice.toFixed(0)}
                                </span>
                            </div>
                        ))}
                        {reviewQueue.length > 3 && (
                            <div style={{ fontSize: 'var(--text-xs)', color: 'var(--rc-text-tertiary)' }}>
                                +{reviewQueue.length - 3} more
                            </div>
                        )}
                    </div>
                </div>
            )}
        </>
    );
}
