import Logo from './Logo.tsx';
import type { TabId } from '../types/index.ts';

interface Tab {
    id: TabId;
    label: string;
    icon: string;
}

interface Props {
    online: boolean | null;
    onRefresh: () => void;
    tabs: Tab[];
    activeTab: TabId;
    onTabChange: (id: TabId) => void;
}

export default function TopNav({ online, onRefresh, tabs, activeTab, onTabChange }: Props) {
    const statusClass =
        online === null ? 'status-badge--loading' : online ? 'status-badge--online' : 'status-badge--offline';
    const dotClass =
        online === null ? '' : online ? 'status-dot--online' : 'status-dot--offline';
    const label =
        online === null ? 'Checking…' : online ? 'Backend Online' : 'Backend Offline';

    return (
        <nav className="topnav">
            <div className="topnav__brand">
                <Logo height={28} />
            </div>
            <div className="topnav__tabs">
                {tabs.map((tab) => (
                    <button
                        key={tab.id}
                        onClick={() => onTabChange(tab.id)}
                        className={`topnav__tab${activeTab === tab.id ? ' topnav__tab--active' : ''}`}
                    >
                        <span>{tab.icon}</span> {tab.label}
                    </button>
                ))}
            </div>
            <div className="topnav__spacer" />
            <div className="topnav__actions">
                <button className={`status-badge ${statusClass}`} onClick={onRefresh} title="Click to refresh">
                    {online !== null && <span className={`status-dot ${dotClass}`} />}
                    {label}
                </button>
            </div>
        </nav>
    );
}
