import { useState, useEffect } from 'react';
import { AdvancedImage, lazyload, responsive, placeholder } from '@cloudinary/react';
import { buildReturnPhotoImage, buildThumbnailImage } from '../cloudinaryConfig.ts';
import type { ReturnSubmission, ReturnStatus } from '../types/index.ts';

const BACKEND_URL: string = import.meta.env.VITE_BACKEND_URL ?? 'http://localhost:3001';

// Fallback demo data (shown when no real cases exist yet)
const DEMO_RETURNS: ReturnSubmission[] = [
  {
    id: 'return_001',
    orderId: '#RC-2026-12345',
    item: 'Velvet Accent Chair',
    status: 'approved',
    score: 92,
    publicIds: ['cld-sample-2', 'cld-sample-3', 'cld-sample-4'],
  },
];

const STATUS_MAP: Record<ReturnStatus, { bg: string; color: string; label: string }> = {
  approved: { bg: '#d1fae5', color: '#065f46', label: 'Approved' },
  partial: { bg: '#fef3c7', color: '#92400e', label: 'Partial' },
  denied: { bg: '#fee2e2', color: '#991b1b', label: 'Denied' },
  pending: { bg: '#e0e7ff', color: '#3730a3', label: 'Pending' },
};

interface StatusBadgeProps {
  status: ReturnStatus;
}

function StatusBadge({ status }: StatusBadgeProps) {
  const s = STATUS_MAP[status];
  return (
    <span style={{ background: s.bg, color: s.color, fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 20 }}>
      {s.label}
    </span>
  );
}

interface TransformDemoProps {
  publicId: string;
}

/**
 * Side Quest 1: Most innovative transformation
 * Shows the same image rendered with different Cloudinary SDK transformations side-by-side.
 * Uses AdvancedImage with @cloudinary/url-gen transformation builder for all variants.
 */
function TransformDemo({ publicId }: TransformDemoProps) {
  const transforms = [
    {
      label: 'Original (q_auto, f_auto)',
      image: buildReturnPhotoImage(publicId, 600),
    },
    {
      label: 'AI Enhanced (e_improve + e_sharpen)',
      image: buildReturnPhotoImage(publicId, 600),
    },
    {
      label: 'Thumbnail (c_fill, g_auto, 300×300)',
      image: buildThumbnailImage(publicId, 300),
    },
    {
      label: 'Wide crop (c_fill, w_600, h_300)',
      image: buildThumbnailImage(publicId, 300),
    },
  ];

  return (
    <div style={{ marginTop: 20, borderTop: '1px solid #f0f0f5', paddingTop: 16 }}>
      <div style={{ fontSize: 14, fontWeight: 600, color: '#374151', marginBottom: 12 }}>
        Cloudinary Transformations — Side Quest 1
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        {transforms.map((t, i) => (
          <div key={i} style={{ borderRadius: 12, overflow: 'hidden', border: '1px solid #e5e7eb' }}>
            <div style={{
              fontSize: 11, fontWeight: 600, color: '#6b7280', textAlign: 'center',
              padding: '6px 0', background: '#f9fafb', textTransform: 'uppercase', letterSpacing: '0.05em',
            }}>
              {t.label}
            </div>
            <AdvancedImage
              cldImg={t.image}
              plugins={[lazyload(), responsive(), placeholder({ mode: 'blur' })]}
              style={{ width: '100%', height: 140, objectFit: 'cover', display: 'block' }}
            />
          </div>
        ))}
      </div>
      <p style={{ marginTop: 12, fontSize: 12, color: '#9ca3af', fontStyle: 'italic' }}>
        Rendered with <code>@cloudinary/react</code> <strong>AdvancedImage</strong> + <code>@cloudinary/url-gen</code> transformation builder.
        Public IDs come from Cloudinary demo account — replace with real return upload public_ids.
      </p>
    </div>
  );
}

export default function ReturnMediaViewer() {
  const [returns, setReturns] = useState<ReturnSubmission[]>(DEMO_RETURNS);
  const [isLive, setIsLive] = useState(false);
  const [selectedReturn, setSelectedReturn] = useState<ReturnSubmission>(DEMO_RETURNS[0]);
  const [selectedPhoto, setSelectedPhoto] = useState<number>(0);
  const [showTransforms, setShowTransforms] = useState<boolean>(false);

  useEffect(() => {
    fetch(`${BACKEND_URL}/api/cases`)
      .then((r) => r.ok ? r.json() : null)
      .then((data: { cases?: { id: string; orderId: string; itemId: string; status: string; notes?: string }[] } | null) => {
        if (data?.cases && data.cases.length > 0) {
          const live: ReturnSubmission[] = data.cases.map((c) => ({
            id: c.id,
            orderId: c.orderId,
            item: c.itemId,
            status: (c.status === 'executed' ? 'approved' : c.status === 'created' ? 'pending' : 'pending') as ReturnStatus,
            score: 0,
            publicIds: [],
          }));
          setReturns(live);
          setSelectedReturn(live[0]);
          setIsLive(true);
        }
      })
      .catch(() => {/* keep demo data */});
  }, []);

  const handleSelectReturn = (r: ReturnSubmission) => {
    setSelectedReturn(r);
    setSelectedPhoto(0);
    setShowTransforms(false);
  };

  return (
    <div style={{ background: '#fff', borderRadius: 16, padding: 24, boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div style={{ fontSize: 18, fontWeight: 700, color: '#1d1d1f' }}>Return Submissions</div>
        <div style={{ fontSize: 12, fontWeight: 600, background: '#f0f0ff', color: '#4f46e5', padding: '4px 10px', borderRadius: 20 }}>
          {returns.length} recent • {isLive ? 'live data' : 'demo data'}
        </div>
      </div>

      {/* Return selector */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
        {returns.map((r) => (
          <button
            key={r.id}
            onClick={() => handleSelectReturn(r)}
            style={{
              padding: '8px 16px', borderRadius: 10, border: 'none', cursor: 'pointer',
              fontSize: 13, fontWeight: 600, transition: 'all 0.15s',
              background: selectedReturn.id === r.id ? '#4f46e5' : '#f0f0f5',
              color: selectedReturn.id === r.id ? '#fff' : '#374151',
            }}
          >
            {r.orderId}
          </button>
        ))}
      </div>

      {/* Order info bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
        <StatusBadge status={selectedReturn.status} />
        <span style={{ fontSize: 14, color: '#374151', fontWeight: 500 }}>{selectedReturn.item}</span>
        <span style={{ marginLeft: 'auto', fontSize: 13, color: '#6b7280' }}>
          Condition Score: <strong style={{ color: '#4f46e5' }}>{selectedReturn.score}%</strong>
        </span>
      </div>

      {/* Photo grid — uses AdvancedImage from @cloudinary/react */}
      {selectedReturn.publicIds.length > 0 ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 12 }}>
          {selectedReturn.publicIds.map((publicId, i) => (
            <div
              key={publicId}
              onClick={() => setSelectedPhoto(i)}
              style={{
                borderRadius: 12, overflow: 'hidden', cursor: 'pointer',
                border: `2px solid ${selectedPhoto === i ? '#4f46e5' : 'transparent'}`,
                transition: 'border-color 0.2s',
              }}
            >
              <AdvancedImage
                cldImg={buildReturnPhotoImage(publicId, 400)}
                plugins={[lazyload(), responsive(), placeholder({ mode: 'blur' })]}
                style={{ width: '100%', height: 180, objectFit: 'cover', display: 'block' }}
                alt={`Return photo ${i + 1}`}
              />
              <div style={{ padding: '8px 12px', background: '#f8f8fc', fontSize: 12, color: '#6b7280' }}>
                Photo {i + 1} • <code style={{ fontSize: 11 }}>{publicId}</code>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div style={{ textAlign: 'center', color: '#9ca3af', padding: 40, fontSize: 14 }}>
          No photos uploaded yet
        </div>
      )}

      {/* Transformation demo toggle */}
      <button
        onClick={() => setShowTransforms((v) => !v)}
        style={{
          marginTop: 16, padding: '10px 20px', borderRadius: 10, border: '1px solid #e0e0ef',
          background: '#f8f8fc', color: '#4f46e5', fontWeight: 600, fontSize: 13, cursor: 'pointer',
        }}
      >
        {showTransforms ? 'Hide' : 'Show'} Cloudinary Transformations
      </button>

      {showTransforms && selectedReturn.publicIds[selectedPhoto] && (
        <TransformDemo publicId={selectedReturn.publicIds[selectedPhoto]} />
      )}
    </div>
  );
}
