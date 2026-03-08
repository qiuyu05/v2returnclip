import { useState, useEffect } from 'react';
import ReturnMediaViewer from './components/ReturnMediaViewer.tsx';
import MerchantVideoUpload from './components/MerchantVideoUpload.tsx';
import UploadWidget from './components/UploadWidget.tsx';
import type { Stat } from './types/index.ts';

const BACKEND_URL: string = import.meta.env.VITE_BACKEND_URL ?? 'http://localhost:3001';

const STATS: Stat[] = [
  { value: '127', label: 'Total Returns', change: '+23 this week', positive: true },
  { value: '94%', label: 'AI Accuracy', change: '+2% vs last month', positive: true },
  { value: '28s', label: 'Avg Processing', change: '-5s vs last month', positive: true },
  { value: '$12.4K', label: 'Revenue Saved', change: '+$1.2K this week', positive: true },
];

type TabId = 'cases' | 'video' | 'upload';

const TABS: { id: TabId; label: string }[] = [
  { id: 'cases', label: 'Return Cases' },
  { id: 'video', label: 'Demo Video' },
  { id: 'upload', label: 'Upload Media' },
];

const TECH_BADGES = ['Cloudinary', 'Gemini AI', 'Shopify', 'SwiftUI'];

export default function App() {
  const [backendOk, setBackendOk] = useState<boolean | null>(null);
  const [activeTab, setActiveTab] = useState<TabId>('cases');

  useEffect(() => {
    fetch(`${BACKEND_URL}/api/health`)
      .then((r) => (r.ok ? r.json() : null))
      .then((d: { status?: string } | null) => setBackendOk(!!d?.status))
      .catch(() => setBackendOk(false));
  }, []);

  return (
    <div style={{ minHeight: '100vh', background: '#f5f5f7' }}>
      {/* Nav */}
      <nav style={{
        background: '#fff', borderBottom: '1px solid #e5e7eb', padding: '0 32px',
        display: 'flex', alignItems: 'center', height: 64, position: 'sticky', top: 0, zIndex: 10,
        boxShadow: '0 1px 8px rgba(0,0,0,0.06)',
      }}>
        <span style={{ fontSize: 20, fontWeight: 800, color: '#4f46e5', letterSpacing: '-0.5px' }}>
          ReturnClip
        </span>
        <span style={{ fontSize: 13, color: '#9ca3af', marginLeft: 8, fontWeight: 500 }}>
          Merchant Dashboard
        </span>
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 16 }}>
          <div style={{ display: 'flex', gap: 6 }}>
            {TECH_BADGES.map((t) => (
              <span key={t} style={{
                fontSize: 11, fontWeight: 600, padding: '3px 10px', borderRadius: 20,
                background: '#f0f0ff', color: '#4f46e5',
              }}>
                {t}
              </span>
            ))}
          </div>
          {backendOk !== null && (
            <span style={{
              fontSize: 12, fontWeight: 600, padding: '4px 12px', borderRadius: 20,
              background: backendOk ? '#d1fae5' : '#fee2e2',
              color: backendOk ? '#065f46' : '#991b1b',
            }}>
              {backendOk ? 'Backend Online' : 'Backend Offline'}
            </span>
          )}
        </div>
      </nav>

      <main style={{ maxWidth: 1200, margin: '0 auto', padding: '32px 24px' }}>
        {/* Stats */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 32 }}>
          {STATS.map((s) => (
            <div key={s.label} style={{
              background: '#fff', borderRadius: 16, padding: '20px 24px',
              boxShadow: '0 2px 12px rgba(0,0,0,0.06)',
            }}>
              <div style={{ fontSize: 32, fontWeight: 800, color: '#4f46e5', lineHeight: 1 }}>{s.value}</div>
              <div style={{ fontSize: 13, color: '#6b7280', marginTop: 6 }}>{s.label}</div>
              <div style={{ fontSize: 12, color: s.positive ? '#16a34a' : '#dc2626', marginTop: 4, fontWeight: 500 }}>
                {s.positive ? '↑' : '↓'} {s.change}
              </div>
            </div>
          ))}
        </div>

        {/* Tab nav */}
        <div style={{
          display: 'flex', gap: 4, marginBottom: 24, background: '#f0f0f5',
          borderRadius: 12, padding: 4, width: 'fit-content',
        }}>
          {TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              style={{
                padding: '8px 20px', borderRadius: 10, border: 'none', cursor: 'pointer',
                fontSize: 14, fontWeight: 600, transition: 'all 0.15s',
                background: activeTab === tab.id ? '#fff' : 'transparent',
                color: activeTab === tab.id ? '#4f46e5' : '#6b7280',
                boxShadow: activeTab === tab.id ? '0 1px 6px rgba(0,0,0,0.1)' : 'none',
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Tab content */}
        {activeTab === 'cases' && <ReturnMediaViewer />}
        {activeTab === 'video' && <MerchantVideoUpload />}
        {activeTab === 'upload' && (
          <div style={{ maxWidth: 600 }}>
            <UploadWidget />
          </div>
        )}

        {/* Architecture footer */}
        <div style={{
          marginTop: 32, padding: 20, background: '#fff', borderRadius: 16,
          boxShadow: '0 2px 12px rgba(0,0,0,0.06)',
        }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#1d1d1f', marginBottom: 10 }}>Architecture</div>
          <div style={{ fontSize: 13, color: '#6b7280', lineHeight: 1.8 }}>
            <strong>App Clip (iOS):</strong> Customer scans QR → Swift app uploads photos to Cloudinary → backend analyzes with Gemini Vision → refund decision shown in seconds<br />
            <strong>Cloudinary role:</strong> CDN for all return photos + demo video, AdvancedImage/AdvancedVideo SDK, Upload Widget for merchants<br />
            <strong>Backend ({BACKEND_URL}):</strong> Calls Gemini Vision with Cloudinary images, Shopify Storefront API for exchange products, Supabase for persistent case data<br />
            <strong>Supabase:</strong> Stores return cases, evidence URLs, execution records, merchant demo video URL — shared source of truth for iOS and web
          </div>
        </div>
      </main>
    </div>
  );
}
