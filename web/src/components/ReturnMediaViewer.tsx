import { useState, useEffect } from 'react';
import { AdvancedImage, lazyload, responsive, placeholder } from '@cloudinary/react';
import { buildReturnPhotoImage, buildThumbnailImage } from '../cloudinaryConfig.ts';

const BACKEND_URL: string = import.meta.env.VITE_BACKEND_URL ?? 'http://localhost:3001';

interface MerchantCase {
  id: string;
  supabaseId: string;
  orderNumber: string;
  itemTitle: string;
  itemPrice: number;
  itemImageUrl: string | null;
  status: string;
  reason: string;
  evidenceUrls: string[];
  exchangeProductTitle: string | null;
  exchangeVariantTitle: string | null;
  exchangePrice: number | null;
  createdAt: string;
}

function extractPublicId(url: string): string {
  const match = url.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.\w+)?$/);
  return match?.[1] ?? url;
}

function formatReason(reason: string): string {
  return reason.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-CA', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function statusStyle(status: string): { bg: string; color: string; label: string } {
  if (status === 'executed') return { bg: '#d1fae5', color: '#065f46', label: 'Resolved' };
  if (status === 'created') return { bg: '#e0e7ff', color: '#3730a3', label: 'Pending' };
  return { bg: '#f3f4f6', color: '#374151', label: status };
}

function StatusBadge({ status }: { status: string }) {
  const s = statusStyle(status);
  return (
    <span style={{ background: s.bg, color: s.color, fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 20 }}>
      {s.label}
    </span>
  );
}

function CaseCard({ c, selected, onClick }: { c: MerchantCase; selected: boolean; onClick: () => void }) {
  return (
    <div
      onClick={onClick}
      style={{
        background: '#fff', borderRadius: 14, padding: 16, cursor: 'pointer',
        border: `2px solid ${selected ? '#4f46e5' : '#e5e7eb'}`,
        boxShadow: selected ? '0 0 0 4px rgba(79,70,229,0.1)' : '0 1px 6px rgba(0,0,0,0.05)',
        transition: 'all 0.15s',
      }}
    >
      <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
        <div style={{ width: 64, height: 64, borderRadius: 10, overflow: 'hidden', background: '#f3f4f6', flexShrink: 0 }}>
          {c.itemImageUrl ? (
            <AdvancedImage
              cldImg={buildThumbnailImage(extractPublicId(c.itemImageUrl), 128)}
              plugins={[lazyload(), placeholder({ mode: 'blur' })]}
              style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
              alt={c.itemTitle}
            />
          ) : (
            <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24 }}>
              📦
            </div>
          )}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#1d1d1f', marginBottom: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {c.itemTitle}
          </div>
          <div style={{ fontSize: 12, color: '#6b7280', marginBottom: 6 }}>
            {c.orderNumber} · ${c.itemPrice.toFixed(2)}
          </div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
            <StatusBadge status={c.status} />
            {c.evidenceUrls.length > 0 && (
              <span style={{ fontSize: 11, color: '#6b7280' }}>{c.evidenceUrls.length} photo{c.evidenceUrls.length !== 1 ? 's' : ''}</span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function ReturnMediaViewer() {
  const [cases, setCases] = useState<MerchantCase[]>([]);
  const [selected, setSelected] = useState<MerchantCase | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedPhoto, setSelectedPhoto] = useState(0);

  useEffect(() => {
    fetch(`${BACKEND_URL}/api/cases`)
      .then((r) => r.ok ? r.json() : null)
      .then((data: { cases?: MerchantCase[] } | null) => {
        const list = data?.cases ?? [];
        setCases(list);
        if (list.length > 0) setSelected(list[0]);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div style={{ background: '#fff', borderRadius: 16, padding: 40, textAlign: 'center', color: '#9ca3af', boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}>
        Loading return cases…
      </div>
    );
  }

  if (cases.length === 0) {
    return (
      <div style={{ background: '#fff', borderRadius: 16, padding: 40, textAlign: 'center', color: '#9ca3af', boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}>
        <div style={{ fontSize: 40, marginBottom: 12 }}>📭</div>
        <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 6, color: '#374151' }}>No return cases yet</div>
        <div style={{ fontSize: 13 }}>Cases will appear here once customers submit returns via the iOS App Clip.</div>
      </div>
    );
  }

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '300px 1fr', gap: 20, alignItems: 'start' }}>
      {/* Left: case list */}
      <div>
        <div style={{ fontSize: 13, fontWeight: 700, color: '#6b7280', marginBottom: 10, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          {cases.length} Return{cases.length !== 1 ? 's' : ''}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {cases.map((c) => (
            <CaseCard
              key={c.id}
              c={c}
              selected={selected?.id === c.id}
              onClick={() => { setSelected(c); setSelectedPhoto(0); }}
            />
          ))}
        </div>
      </div>

      {/* Right: detail */}
      {selected && (
        <div style={{ background: '#fff', borderRadius: 16, padding: 24, boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20 }}>
            <div>
              <div style={{ fontSize: 20, fontWeight: 800, color: '#1d1d1f', marginBottom: 4 }}>{selected.itemTitle}</div>
              <div style={{ fontSize: 13, color: '#6b7280' }}>{selected.orderNumber} · {formatDate(selected.createdAt)}</div>
            </div>
            <StatusBadge status={selected.status} />
          </div>

          {/* Item details */}
          <div style={{ display: 'flex', gap: 16, marginBottom: 20, padding: 16, background: '#f8f8fc', borderRadius: 12 }}>
            {selected.itemImageUrl ? (
              <div style={{ width: 80, height: 80, borderRadius: 10, overflow: 'hidden', flexShrink: 0 }}>
                <AdvancedImage
                  cldImg={buildThumbnailImage(extractPublicId(selected.itemImageUrl), 160)}
                  plugins={[lazyload(), responsive(), placeholder({ mode: 'blur' })]}
                  style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                  alt={selected.itemTitle}
                />
              </div>
            ) : (
              <div style={{ width: 80, height: 80, borderRadius: 10, background: '#e5e7eb', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 36, flexShrink: 0 }}>
                📦
              </div>
            )}
            <div>
              <div style={{ fontSize: 15, fontWeight: 700, color: '#1d1d1f', marginBottom: 4 }}>{selected.itemTitle}</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: '#4f46e5', marginBottom: 6 }}>${selected.itemPrice.toFixed(2)}</div>
              <div style={{ fontSize: 13, color: '#6b7280' }}>
                Reason: <strong style={{ color: '#374151' }}>{formatReason(selected.reason)}</strong>
              </div>
            </div>
          </div>

          {/* Exchange info */}
          {selected.exchangeProductTitle && (
            <div style={{ marginBottom: 20, padding: 14, background: '#fefce8', borderRadius: 12, border: '1px solid #fde68a' }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: '#92400e', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Exchange Selected
              </div>
              <div style={{ fontSize: 15, fontWeight: 700, color: '#1d1d1f' }}>{selected.exchangeProductTitle}</div>
              {selected.exchangeVariantTitle && (
                <div style={{ fontSize: 13, color: '#6b7280', marginTop: 2 }}>{selected.exchangeVariantTitle}</div>
              )}
              {selected.exchangePrice != null && (
                <div style={{ fontSize: 20, fontWeight: 800, color: '#d97706', marginTop: 4 }}>${selected.exchangePrice.toFixed(2)}</div>
              )}
            </div>
          )}

          {/* Evidence photos */}
          <div style={{ fontSize: 14, fontWeight: 700, color: '#374151', marginBottom: 12 }}>
            Customer Evidence Photos ({selected.evidenceUrls.length})
          </div>
          {selected.evidenceUrls.length > 0 ? (
            <>
              <div style={{ borderRadius: 12, overflow: 'hidden', marginBottom: 12, background: '#0a0a0a', maxHeight: 340, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <AdvancedImage
                  cldImg={buildReturnPhotoImage(extractPublicId(selected.evidenceUrls[selectedPhoto]), 800)}
                  plugins={[lazyload(), responsive(), placeholder({ mode: 'blur' })]}
                  style={{ width: '100%', maxHeight: 340, objectFit: 'contain', display: 'block' }}
                  alt={`Evidence photo ${selectedPhoto + 1}`}
                />
              </div>
              {selected.evidenceUrls.length > 1 && (
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  {selected.evidenceUrls.map((url, i) => (
                    <div
                      key={i}
                      onClick={() => setSelectedPhoto(i)}
                      style={{
                        width: 72, height: 72, borderRadius: 10, overflow: 'hidden', cursor: 'pointer',
                        border: `2px solid ${selectedPhoto === i ? '#4f46e5' : 'transparent'}`,
                        flexShrink: 0,
                      }}
                    >
                      <AdvancedImage
                        cldImg={buildThumbnailImage(extractPublicId(url), 144)}
                        plugins={[lazyload(), placeholder({ mode: 'blur' })]}
                        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                        alt={`Thumb ${i + 1}`}
                      />
                    </div>
                  ))}
                </div>
              )}
            </>
          ) : (
            <div style={{ padding: 32, textAlign: 'center', color: '#9ca3af', fontSize: 13, background: '#f9fafb', borderRadius: 12 }}>
              No evidence photos uploaded yet
            </div>
          )}
        </div>
      )}
    </div>
  );
}
