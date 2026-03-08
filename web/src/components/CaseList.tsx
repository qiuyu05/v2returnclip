import { AdvancedImage, lazyload, placeholder } from '@cloudinary/react';
import { buildThumbnailImage, isCloudinaryUrl } from '../cloudinaryConfig.ts';
import type { MerchantCase } from '../types/index.ts';

interface Props {
    cases: MerchantCase[];
    selected: MerchantCase | null;
    loading: boolean;
    error: string | null;
    onSelect: (c: MerchantCase) => void;
}

function extractPublicId(url: string): string {
    const match = url.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.\w+)?$/);
    return match?.[1] ?? url;
}

function statusBadge(status: string) {
    if (status === 'executed') return { cls: 'badge--resolved', label: 'Resolved' };
    if (status === 'created') return { cls: 'badge--pending', label: 'Pending' };
    if (status === 'denied') return { cls: 'badge--denied', label: 'Denied' };
    if (status === 'reviewing') return { cls: 'badge--review', label: 'Reviewing' };
    if (status === 'exchange') return { cls: 'badge--exchange', label: 'Exchange' };
    return { cls: 'badge--pending', label: status };
}

function riskBadge(level?: string) {
    if (level === 'high') return { cls: 'badge--risk-high', label: '🔴 High' };
    if (level === 'medium') return { cls: 'badge--risk-medium', label: '🟡 Med' };
    return null; // don't show low risk
}

export default function CaseList({ cases, selected, loading, error, onSelect }: Props) {
    if (loading) {
        return (
            <div className="case-list">
                {Array.from({ length: 4 }).map((_, i) => (
                    <div key={i} className="skeleton skeleton--card" />
                ))}
            </div>
        );
    }

    if (error) {
        return (
            <div className="empty-state">
                <div className="empty-state__icon">⚠️</div>
                <div className="empty-state__title">Error loading cases</div>
                <div className="empty-state__desc">{error}</div>
            </div>
        );
    }

    if (cases.length === 0) {
        return (
            <div className="empty-state">
                <div className="empty-state__icon">📭</div>
                <div className="empty-state__title">No cases match filters</div>
                <div className="empty-state__desc">Try adjusting your search or filters.</div>
            </div>
        );
    }

    return (
        <div className="case-list">
            {cases.map((c) => {
                const s = statusBadge(c.status);
                const r = riskBadge(c.riskLevel);
                const isSelected = selected?.id === c.id;
                return (
                    <div
                        key={c.id}
                        className={`case-card ${isSelected ? 'case-card--selected' : ''}`}
                        onClick={() => onSelect(c)}
                    >
                        <div className="case-card__thumb">
                            {c.itemImageUrl ? (
                                isCloudinaryUrl(c.itemImageUrl) ? (
                                    <AdvancedImage
                                        cldImg={buildThumbnailImage(extractPublicId(c.itemImageUrl), 112)}
                                        plugins={[lazyload(), placeholder({ mode: 'blur' })]}
                                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                        alt={c.itemTitle}
                                    />
                                ) : (
                                    <img
                                        src={c.itemImageUrl}
                                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                        alt={c.itemTitle}
                                        loading="lazy"
                                    />
                                )
                            ) : (
                                <span style={{ fontSize: 24 }}>📦</span>
                            )}
                        </div>
                        <div className="case-card__body">
                            <div className="case-card__title">{c.itemTitle}</div>
                            <div className="case-card__meta">
                                {c.orderNumber} · ${c.itemPrice.toFixed(2)}
                            </div>
                            <div className="case-card__tags">
                                <span className={`badge ${s.cls}`}>{s.label}</span>
                                {r && <span className={`badge ${r.cls}`}>{r.label}</span>}
                                {c.evidenceUrls.length > 0 && (
                                    <span style={{ fontSize: 11, color: 'var(--rc-text-secondary)' }}>
                                        📷 {c.evidenceUrls.length}
                                    </span>
                                )}
                            </div>
                        </div>
                    </div>
                );
            })}
        </div>
    );
}
