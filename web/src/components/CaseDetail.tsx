import { useState } from 'react';
import { AdvancedImage, lazyload, responsive, placeholder } from '@cloudinary/react';
import { buildReturnPhotoImage, buildThumbnailImage, isCloudinaryUrl } from '../cloudinaryConfig.ts';
import type { MerchantCase, ToastType } from '../types/index.ts';

interface Props {
    case_: MerchantCase;
    onAction: (type: ToastType, message: string) => void;
    onUpdate: (id: string, patch: Partial<MerchantCase>) => void;
}

function extractPublicId(url: string): string {
    const match = url.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.\w+)?$/);
    return match?.[1] ?? url;
}

function formatReason(reason: string): string {
    return reason.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

function formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString('en-US', {
        month: 'short', day: 'numeric', year: 'numeric',
        hour: '2-digit', minute: '2-digit',
    });
}

function statusLabel(s: string): { cls: string; label: string } {
    if (s === 'executed') return { cls: 'badge--resolved', label: 'Resolved' };
    if (s === 'created') return { cls: 'badge--pending', label: 'Pending' };
    if (s === 'denied') return { cls: 'badge--denied', label: 'Denied' };
    if (s === 'reviewing') return { cls: 'badge--review', label: 'Reviewing' };
    if (s === 'exchange') return { cls: 'badge--exchange', label: 'Exchange' };
    return { cls: 'badge--pending', label: s };
}

export default function CaseDetail({ case_: c, onAction, onUpdate }: Props) {
    const [photoIdx, setPhotoIdx] = useState(0);
    const [zoomOpen, setZoomOpen] = useState(false);
    const [enhancedView, setEnhancedView] = useState(true);
    const s = statusLabel(c.status);

    const handleApprove = () => {
        onUpdate(c.id, { status: 'executed' });
        onAction('success', `Refund approved for ${c.orderNumber}`);
    };

    const handleDeny = () => {
        onUpdate(c.id, { status: 'denied' });
        onAction('error', `Return denied for ${c.orderNumber}`);
    };

    const handleReview = () => {
        onUpdate(c.id, { status: 'reviewing' });
        onAction('warning', `${c.orderNumber} sent to manual review`);
    };

    const handleExchange = () => {
        onUpdate(c.id, { status: 'exchange' });
        onAction('info', `Exchange offered for ${c.orderNumber}`);
    };

    const handleStoreCredit = () => {
        onAction('info', `Store credit bonus sent for ${c.orderNumber}`);
    };

    const handleCopyId = () => {
        navigator.clipboard.writeText(c.id);
        onAction('info', `Copied ${c.id}`);
    };

    return (
        <div className="case-detail">
            {/* Header */}
            <div className="case-detail__header">
                <div>
                    <div className="case-detail__title">{c.itemTitle}</div>
                    <div className="case-detail__subtitle">
                        {c.orderNumber} · {formatDate(c.createdAt)}
                    </div>
                </div>
                <span className={`badge ${s.cls}`}>{s.label}</span>
            </div>

            {/* Item info */}
            <div className="case-detail__info-grid">
                <div className="case-detail__info-thumb">
                    {c.itemImageUrl ? (
                        isCloudinaryUrl(c.itemImageUrl) ? (
                            <AdvancedImage
                                cldImg={buildThumbnailImage(extractPublicId(c.itemImageUrl), 144)}
                                plugins={[lazyload(), responsive(), placeholder({ mode: 'blur' })]}
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
                        <span>📦</span>
                    )}
                </div>
                <div>
                    <div style={{ fontSize: 'var(--text-md)', fontWeight: 700, color: 'var(--rc-text-primary)', marginBottom: 4 }}>
                        {c.itemTitle}
                    </div>
                    <div className="case-detail__price">${c.itemPrice.toFixed(2)}</div>
                    <div style={{ fontSize: 'var(--text-sm)', color: 'var(--rc-text-secondary)' }}>
                        Reason: <strong style={{ color: 'var(--rc-text-primary)' }}>{formatReason(c.reason)}</strong>
                    </div>
                    {c.riskLevel && (
                        <div style={{ marginTop: 6 }}>
                            <span className={`badge badge--risk-${c.riskLevel}`}>
                                {c.riskLevel === 'high' ? '🔴' : c.riskLevel === 'medium' ? '🟡' : '🟢'} {c.riskLevel.charAt(0).toUpperCase() + c.riskLevel.slice(1)} Risk
                            </span>
                        </div>
                    )}
                </div>
            </div>

            {/* Exchange info */}
            {c.exchangeProductTitle && (
                <div className="exchange-card">
                    <div className="exchange-card__label">Exchange Selected</div>
                    <div style={{ fontSize: 'var(--text-md)', fontWeight: 700 }}>{c.exchangeProductTitle}</div>
                    {c.exchangeVariantTitle && (
                        <div style={{ fontSize: 'var(--text-sm)', color: 'var(--rc-text-secondary)', marginTop: 2 }}>
                            {c.exchangeVariantTitle}
                        </div>
                    )}
                    {c.exchangePrice != null && (
                        <div className="exchange-card__price">${c.exchangePrice.toFixed(2)}</div>
                    )}
                </div>
            )}

            {/* Workflow Actions */}
            <div className="action-group">
                <div className="action-group__title">Workflow Actions</div>
                <button className="action-btn action-btn--success" onClick={handleApprove}>
                    <span>✓</span> Approve Refund
                </button>
                <button className="action-btn action-btn--warning" onClick={handleExchange}>
                    <span>🔄</span> Offer Exchange
                </button>
                <button className="action-btn" onClick={handleStoreCredit}>
                    <span>🎁</span> Offer Store Credit Bonus
                </button>
                <button className="action-btn" onClick={handleReview}>
                    <span>👁</span> Force Manual Review
                </button>
                <div style={{ display: 'flex', gap: 8 }}>
                    <button className="action-btn action-btn--danger" onClick={handleDeny} style={{ flex: 1 }}>
                        <span>✕</span> Deny Return
                    </button>
                    <button className="action-btn action-btn--ghost" onClick={handleCopyId} title="Copy return ID">
                        <span>📋</span> Copy ID
                    </button>
                </div>
            </div>

            {/* Evidence Photos */}
            <div className="evidence-gallery">
                <div className="section-header">
                    Customer Evidence ({c.evidenceUrls.length})
                    {c.evidenceUrls.length > 0 && (
                        <button
                            className="action-btn action-btn--ghost"
                            style={{ fontSize: 11, padding: '2px 8px', marginLeft: 8 }}
                            onClick={() => setEnhancedView(!enhancedView)}
                        >
                            {enhancedView ? '🔍 Enhanced' : '📷 Original'}
                        </button>
                    )}
                </div>
                {c.evidenceUrls.length > 0 ? (
                    <>
                        <div
                            className="evidence-gallery__main"
                            onClick={() => setZoomOpen(true)}
                            style={{ cursor: 'zoom-in' }}
                        >
                            {isCloudinaryUrl(c.evidenceUrls[photoIdx]) ? (
                                <AdvancedImage
                                    cldImg={
                                        enhancedView
                                            ? buildReturnPhotoImage(extractPublicId(c.evidenceUrls[photoIdx]), 800)
                                            : buildThumbnailImage(extractPublicId(c.evidenceUrls[photoIdx]), 800)
                                    }
                                    plugins={[lazyload(), responsive(), placeholder({ mode: 'blur' })]}
                                    style={{ width: '100%', maxHeight: 320, objectFit: 'contain' }}
                                    alt={`Evidence ${photoIdx + 1}`}
                                />
                            ) : (
                                <img
                                    src={c.evidenceUrls[photoIdx]}
                                    style={{ width: '100%', maxHeight: 320, objectFit: 'contain' }}
                                    alt={`Evidence ${photoIdx + 1}`}
                                    loading="lazy"
                                />
                            )}
                        </div>
                        {c.evidenceUrls.length > 1 && (
                            <div className="evidence-gallery__thumbs">
                                {c.evidenceUrls.map((url, i) => (
                                    <div
                                        key={i}
                                        className={`evidence-thumb ${photoIdx === i ? 'evidence-thumb--active' : ''}`}
                                        onClick={() => setPhotoIdx(i)}
                                    >
                                        {isCloudinaryUrl(url) ? (
                                            <AdvancedImage
                                                cldImg={buildThumbnailImage(extractPublicId(url), 128)}
                                                plugins={[lazyload(), placeholder({ mode: 'blur' })]}
                                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                                alt={`Thumb ${i + 1}`}
                                            />
                                        ) : (
                                            <img
                                                src={url}
                                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                                alt={`Thumb ${i + 1}`}
                                                loading="lazy"
                                            />
                                        )}
                                    </div>
                                ))}
                            </div>
                        )}
                    </>
                ) : (
                    <div className="empty-state" style={{ padding: 'var(--sp-8) var(--sp-4)' }}>
                        <div className="empty-state__icon">📷</div>
                        <div className="empty-state__desc">No evidence photos uploaded</div>
                    </div>
                )}
            </div>

            {/* Zoom Modal */}
            {zoomOpen && c.evidenceUrls.length > 0 && (
                <div className="zoom-modal" onClick={() => setZoomOpen(false)}>
                    <button className="zoom-modal__close" onClick={() => setZoomOpen(false)}>✕</button>
                    <div className="zoom-modal__content" onClick={(e) => e.stopPropagation()}>
                        {isCloudinaryUrl(c.evidenceUrls[photoIdx]) ? (
                            <AdvancedImage
                                className="zoom-modal__img"
                                cldImg={buildReturnPhotoImage(extractPublicId(c.evidenceUrls[photoIdx]), 1400)}
                                plugins={[lazyload(), placeholder({ mode: 'blur' })]}
                                alt={`Zoomed evidence ${photoIdx + 1}`}
                            />
                        ) : (
                            <img
                                className="zoom-modal__img"
                                src={c.evidenceUrls[photoIdx]}
                                alt={`Zoomed evidence ${photoIdx + 1}`}
                            />
                        )}
                        <div className="zoom-modal__sidebar">
                            <div className="zoom-modal__label">Evidence Photo {photoIdx + 1} of {c.evidenceUrls.length}</div>
                            <div style={{ fontSize: 14 }}>
                                <strong>{c.itemTitle}</strong><br />
                                {c.orderNumber} · {formatReason(c.reason)}
                            </div>
                            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 8 }}>
                                {c.evidenceUrls.map((url, i) => (
                                    <button
                                        key={i}
                                        onClick={() => setPhotoIdx(i)}
                                        style={{
                                            width: 48, height: 48, borderRadius: 8, overflow: 'hidden',
                                            border: photoIdx === i ? '2px solid white' : '2px solid transparent',
                                            background: 'rgba(255,255,255,0.1)', cursor: 'pointer',
                                        }}
                                    >
                                        {isCloudinaryUrl(url) ? (
                                            <AdvancedImage
                                                cldImg={buildThumbnailImage(extractPublicId(url), 96)}
                                                plugins={[lazyload(), placeholder({ mode: 'blur' })]}
                                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                                alt=""
                                            />
                                        ) : (
                                            <img
                                                src={url}
                                                alt=""
                                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                                loading="lazy"
                                            />
                                        )}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
