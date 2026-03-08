// ============================================================
// ReturnClip Shared Types — Dashboard + API
// ============================================================

// ---------- Return Case ----------
export type CaseStatus = 'created' | 'executed' | 'denied' | 'reviewing' | 'exchange';

export type RiskLevel = 'low' | 'medium' | 'high';

export type ReturnReason =
  | 'damaged'
  | 'wrong_item'
  | 'not_as_described'
  | 'defective'
  | 'changed_mind'
  | 'too_large'
  | 'too_small'
  | 'other';

export interface MerchantCase {
  id: string;
  supabaseId: string;
  orderNumber: string;
  itemTitle: string;
  itemPrice: number;
  itemImageUrl: string | null;
  status: CaseStatus | string;
  reason: ReturnReason | string;
  evidenceUrls: string[];
  exchangeProductTitle: string | null;
  exchangeVariantTitle: string | null;
  exchangePrice: number | null;
  createdAt: string;
  // Enriched client-side fields
  riskLevel?: RiskLevel;
  aiConfidence?: number;
  customerName?: string;
}

export interface CasesApiResponse {
  cases: MerchantCase[];
}

// ---------- KPI / Stats ----------
export interface Stat {
  value: string;
  label: string;
  change: string;
  positive: boolean;
  icon?: string;
  iconBg?: string;
}

export interface DashboardStats {
  totalReturns: number;
  aiAccuracy: number;
  avgProcessingTime: number;
  revenueSaved: number;
  fraudPrevented: number;
  exchangeRate: number;
  pendingReview: number;
}

// ---------- Filters ----------
export interface CaseFilters {
  search: string;
  status: CaseStatus | 'all';
  riskLevel: RiskLevel | 'all';
  reason: ReturnReason | 'all';
  dateRange: 'all' | '7d' | '30d' | '90d';
}

// ---------- Toast ----------
export type ToastType = 'success' | 'error' | 'info' | 'warning';

export interface Toast {
  id: string;
  type: ToastType;
  message: string;
}

// ---------- Uploads ----------
export type TabId = 'overview' | 'video' | 'upload';

export interface ReturnSubmission {
  id: string;
  orderId: string;
  item: string;
  status: CaseStatus;
  score: number;
  publicIds: string[];
}

export interface UploadedFile {
  publicId: string;
  secureUrl: string;
  format: string;
  resourceType: 'image' | 'video' | 'raw';
  bytes: number;
  width?: number;
  height?: number;
}

export interface VideoTransform {
  icon: string;
  name: string;
  code: string;
  desc: string;
}

// ---------- Cloudinary Upload Widget ----------
declare global {
  interface Window {
    cloudinary: {
      createUploadWidget: (
        options: CloudinaryWidgetOptions,
        callback: (error: CloudinaryWidgetError | null, result: CloudinaryWidgetResult) => void
      ) => CloudinaryWidget;
    };
  }
}

export interface CloudinaryWidgetOptions {
  cloudName: string;
  uploadPreset: string;
  sources?: string[];
  multiple?: boolean;
  maxFiles?: number;
  maxFileSize?: number;
  resourceType?: string;
  folder?: string;
  tags?: string[];
  showAdvancedOptions?: boolean;
  cropping?: boolean;
  styles?: {
    palette?: Record<string, string>;
  };
}

export interface CloudinaryWidgetError {
  message: string;
  status: number;
}

export interface CloudinaryWidgetResult {
  event: string;
  info: CloudinaryUploadInfo;
}

export interface CloudinaryUploadInfo {
  public_id: string;
  secure_url: string;
  format: string;
  resource_type: 'image' | 'video' | 'raw';
  bytes: number;
  width?: number;
  height?: number;
}

export interface CloudinaryWidget {
  open: () => void;
  close: () => void;
  destroy: () => void;
}

// ---------- Backend Health ----------
export interface HealthResponse {
  status: string;
}

export interface MerchantVideoResponse {
  videoUrl?: string;
}
