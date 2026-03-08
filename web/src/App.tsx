import { useState } from 'react';
import TopNav from './components/TopNav.tsx';
import KpiRow from './components/KpiRow.tsx';
import CaseFiltersSidebar from './components/CaseFiltersSidebar.tsx';
import CaseList from './components/CaseList.tsx';
import CaseDetail from './components/CaseDetail.tsx';
import RightPanel from './components/RightPanel.tsx';
import MerchantVideoUpload from './components/MerchantVideoUpload.tsx';
import UploadWidget from './components/UploadWidget.tsx';
import ToastContainer from './components/ToastContainer.tsx';
import { useBackendHealth } from './hooks/useBackendHealth.ts';
import { useCases } from './hooks/useCases.ts';
import { useToast } from './hooks/useToast.ts';
import type { TabId } from './types/index.ts';

const TABS: { id: TabId; label: string; icon: string }[] = [
  { id: 'overview', label: 'Return Cases', icon: '📦' },
  { id: 'video', label: 'Demo Video', icon: '🎬' },
  { id: 'upload', label: 'Upload Media', icon: '📤' },
];

export default function App() {
  const { online, refresh: refreshHealth } = useBackendHealth();
  const {
    cases, allCases, loading, error,
    selected, setSelected,
    filters, setFilters,
    updateCase, stats,
  } = useCases();
  const { toasts, addToast, removeToast } = useToast();
  const [activeTab, setActiveTab] = useState<TabId>('overview');

  return (
    <div style={{ minHeight: '100vh', background: 'var(--rc-bg)' }}>
      <TopNav online={online} onRefresh={refreshHealth} tabs={TABS} activeTab={activeTab} onTabChange={setActiveTab} />
      <ToastContainer toasts={toasts} onRemove={removeToast} />

      {activeTab === 'overview' ? (
        <>
          {/* KPI Row */}
          <div style={{ maxWidth: 'var(--content-max)', margin: '0 auto', padding: 'var(--sp-6) var(--sp-6) 0' }}>
            <KpiRow stats={stats} loading={loading} />
          </div>

          {/* 3-column dashboard */}
          <div className="dashboard">
            {/* Left sidebar: filters + case list */}
            <div className="dashboard__sidebar custom-scroll">
              <CaseFiltersSidebar
                filters={filters}
                onChange={setFilters}
                caseCount={cases.length}
                totalCount={allCases.length}
              />
              <div style={{ marginTop: 'var(--sp-4)' }}>
                <CaseList
                  cases={cases}
                  selected={selected}
                  loading={loading}
                  error={error}
                  onSelect={setSelected}
                />
              </div>
            </div>

            {/* Main: case detail */}
            <div className="dashboard__main custom-scroll">
              {selected ? (
                <CaseDetail
                  case_={selected}
                  onAction={addToast}
                  onUpdate={updateCase}
                />
              ) : (
                <div className="empty-state">
                  <div className="empty-state__icon">👈</div>
                  <div className="empty-state__title">Select a case</div>
                  <div className="empty-state__desc">Choose a return case from the left to view details.</div>
                </div>
              )}
            </div>

            {/* Right: AI + merchant modules */}
            <div className="dashboard__right custom-scroll">
              <RightPanel case_={selected} stats={stats} allCases={allCases} />
            </div>
          </div>
        </>
      ) : (
        /* Video / Upload tabs */
        <main style={{ maxWidth: 800, margin: '0 auto', padding: 'var(--sp-8) var(--sp-6)' }}>
          {activeTab === 'video' && <MerchantVideoUpload />}
          {activeTab === 'upload' && <UploadWidget />}
        </main>
      )}

    </div>
  );
}
