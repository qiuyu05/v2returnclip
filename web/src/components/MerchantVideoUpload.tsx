import { useEffect, useRef, useState } from 'react';
import { AdvancedVideo, lazyload } from '@cloudinary/react';
import { CLOUD_NAME, UPLOAD_PRESET, buildReturnVideo, buildVideoThumbnailUrl } from '../cloudinaryConfig.ts';
import type { CloudinaryWidgetOptions } from '../types/index.ts';

const BACKEND_URL: string = import.meta.env.VITE_BACKEND_URL ?? 'http://localhost:3001';

const WIDGET_OPTIONS: CloudinaryWidgetOptions = {
  cloudName: CLOUD_NAME,
  uploadPreset: UPLOAD_PRESET,
  sources: ['local', 'url'],
  multiple: false,
  maxFiles: 1,
  maxFileSize: 200_000_000, // 200 MB
  resourceType: 'video',
  folder: 'returnclip/demo',
  tags: ['returnclip', 'demo-video'],
  showAdvancedOptions: false,
  cropping: false,
  styles: {
    palette: {
      window: '#FFFFFF',
      windowBorder: '#90A0B3',
      tabIcon: '#4f46e5',
      menuIcons: '#4f46e5',
      textDark: '#1d1d1f',
      textLight: '#FFFFFF',
      link: '#4f46e5',
      action: '#4f46e5',
      inactiveTabIcon: '#9CA3AF',
      error: '#EF4444',
      inProgress: '#4f46e5',
      complete: '#22C55E',
      sourceBg: '#F9FAFB',
    },
  },
};

export default function MerchantVideoUpload() {
  const widgetRef = useRef<ReturnType<typeof window.cloudinary.createUploadWidget> | null>(null);
  const [widgetReady, setWidgetReady] = useState(false);
  const [currentVideoUrl, setCurrentVideoUrl] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState<string | null>(null);
  const [playing, setPlaying] = useState(false);

  // Load Cloudinary widget script
  useEffect(() => {
    if (window.cloudinary) { setWidgetReady(true); return; }
    const script = document.createElement('script');
    script.src = 'https://upload-widget.cloudinary.com/global/all.js';
    script.async = true;
    script.onload = () => setWidgetReady(true);
    document.head.appendChild(script);
    return () => { document.head.removeChild(script); };
  }, []);

  // Fetch current demo video from backend
  useEffect(() => {
    fetch(`${BACKEND_URL}/api/merchant/video`)
      .then((r) => r.ok ? r.json() : null)
      .then((data: { videoUrl?: string } | null) => {
        if (data?.videoUrl) setCurrentVideoUrl(data.videoUrl);
      })
      .catch(() => {});
  }, []);

  async function saveVideoUrl(url: string) {
    setSaving(true);
    setSaveMsg(null);
    try {
      const resp = await fetch(`${BACKEND_URL}/api/merchant/video`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ videoUrl: url }),
      });
      if (resp.ok) {
        setCurrentVideoUrl(url);
        setPlaying(false);
        setSaveMsg('Video saved! Swift app will show this on next order lookup.');
      } else {
        setSaveMsg('Failed to save. Try again.');
      }
    } catch {
      setSaveMsg('Network error saving video.');
    } finally {
      setSaving(false);
    }
  }

  function openWidget() {
    if (!widgetReady || !window.cloudinary) {
      alert('Upload widget loading, please retry.');
      return;
    }
    if (!widgetRef.current) {
      widgetRef.current = window.cloudinary.createUploadWidget(
        WIDGET_OPTIONS,
        (error, result) => {
          if (error) { console.error('[VideoUpload]', error); return; }
          if (result.event === 'success') {
            saveVideoUrl(result.info.secure_url);
          }
        }
      );
    }
    widgetRef.current.open();
  }

  // Extract public_id from a Cloudinary URL for use with AdvancedVideo
  function extractPublicId(url: string): string {
    const match = url.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.\w+)?$/);
    return match?.[1] ?? '';
  }

  const publicId = currentVideoUrl ? extractPublicId(currentVideoUrl) : null;
  const thumbUrl = publicId ? buildVideoThumbnailUrl(publicId, 2) : null;
  const cldVideo = publicId ? buildReturnVideo(publicId) : null;

  return (
    <div style={{ background: '#fff', borderRadius: 16, padding: 24, boxShadow: '0 2px 12px rgba(0,0,0,0.08)', maxWidth: 680 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div style={{ fontSize: 18, fontWeight: 700, color: '#1d1d1f' }}>Packaging Demo Video</div>
        <div style={{ fontSize: 12, fontWeight: 600, background: '#fff0e6', color: '#c05621', padding: '4px 10px', borderRadius: 20 }}>
          Shown in Swift App
        </div>
      </div>

      <p style={{ fontSize: 13, color: '#6b7280', marginBottom: 20, lineHeight: 1.6 }}>
        Upload a video showing customers how to fold, disassemble, or package their return.
        This video is fetched by the iOS App Clip and shown during the return flow.
      </p>

      {/* Current video */}
      {cldVideo && thumbUrl ? (
        <div style={{ marginBottom: 24 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: '#374151', marginBottom: 10 }}>Current Demo Video</div>
          <div style={{ position: 'relative', borderRadius: 12, overflow: 'hidden', background: '#0a0a0a', aspectRatio: '16/9' }}>
            {playing ? (
              <AdvancedVideo
                cldVid={cldVideo}
                plugins={[lazyload()]}
                controls
                autoPlay
                poster={thumbUrl}
                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              />
            ) : (
              <>
                <img
                  src={thumbUrl}
                  alt="Video poster"
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
                <div style={{
                  position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
                  alignItems: 'center', justifyContent: 'center', gap: 12,
                }}>
                  <button
                    onClick={() => setPlaying(true)}
                    style={{
                      width: 64, height: 64, borderRadius: '50%', background: 'rgba(255,255,255,0.9)',
                      border: 'none', cursor: 'pointer', fontSize: 24,
                      boxShadow: '0 4px 20px rgba(0,0,0,0.4)',
                    }}
                  >
                    ▶
                  </button>
                  <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: 13, fontWeight: 500 }}>
                    Cloudinary CDN · adaptive quality
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      ) : (
        <div style={{ marginBottom: 24, padding: 32, textAlign: 'center', background: '#f9fafb', borderRadius: 12, color: '#9ca3af' }}>
          <div style={{ fontSize: 36, marginBottom: 8 }}>🎥</div>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#374151', marginBottom: 4 }}>No demo video set</div>
          <div style={{ fontSize: 13 }}>Upload one below to guide customers through packaging.</div>
        </div>
      )}

      {/* Upload button */}
      <button
        onClick={openWidget}
        disabled={!widgetReady || saving}
        style={{
          width: '100%', padding: '14px 0', borderRadius: 12, border: 'none',
          background: widgetReady && !saving ? '#4f46e5' : '#a5b4fc',
          color: '#fff', fontSize: 15, fontWeight: 700,
          cursor: widgetReady && !saving ? 'pointer' : 'not-allowed',
          marginBottom: 12,
        }}
      >
        {saving ? 'Saving…' : widgetReady ? (currentVideoUrl ? 'Replace Demo Video' : 'Upload Demo Video') : 'Loading…'}
      </button>

      {saveMsg && (
        <div style={{
          padding: '10px 14px', borderRadius: 10, fontSize: 13, fontWeight: 500,
          background: saveMsg.startsWith('Video saved') ? '#d1fae5' : '#fee2e2',
          color: saveMsg.startsWith('Video saved') ? '#065f46' : '#991b1b',
        }}>
          {saveMsg}
        </div>
      )}
    </div>
  );
}
