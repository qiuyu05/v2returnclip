import type { Toast } from '../types/index.ts';

interface Props {
    toasts: Toast[];
    onRemove: (id: string) => void;
}

const ICONS: Record<string, string> = {
    success: '✓',
    error: '✕',
    info: 'ℹ',
    warning: '⚠',
};

export default function ToastContainer({ toasts, onRemove }: Props) {
    if (toasts.length === 0) return null;
    return (
        <div className="toast-container">
            {toasts.map((t) => (
                <div key={t.id} className={`toast toast--${t.type}`}>
                    <span>{ICONS[t.type] ?? ''}</span>
                    <span>{t.message}</span>
                    <button className="toast__close" onClick={() => onRemove(t.id)}>×</button>
                </div>
            ))}
        </div>
    );
}
