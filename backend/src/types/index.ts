// Shared types mirroring Swift models

export interface Order {
  id: string;
  orderNumber: string;
  purchaseDate: string;
  purchaseLocation: string;
  customerEmail: string;
  customerName: string;
  lineItems: LineItem[];
  totalPrice: number;
  currency: string;
  paymentMethod: PaymentMethod;
}

export interface LineItem {
  id: string;
  productId: string;
  variantId: string;
  title: string;
  variantTitle?: string;
  sku: string;
  quantity: number;
  price: number;
  imageUrl?: string;
  packagingVideoUrl?: string;  // per-item packaging tutorial video set by merchant
}

export interface PaymentMethod {
  type: 'card' | 'applePay' | 'shopPay' | 'paypal';
  lastFour?: string;
  brand?: string;
}

export interface ReturnPolicy {
  id: string;
  merchantName: string;
  returnWindowDays: number;
  conditionRequirements: ConditionRequirement[];
  restockingFeeThreshold: number;
  restockingFeePercent: number;
  allowExchange: boolean;
  allowStoreCredit: boolean;
  storeCreditBonus?: number;
  requiresPhotos: boolean;
  requiresVideo: boolean;
  demoVideoUrl?: string;
  shippingPaidBy: 'merchant' | 'customer' | 'split';
  processingDays: number;
}

export interface ConditionRequirement {
  category: ConditionCategory;
  maxAllowedScore: number;
  description: string;
}

export type ConditionCategory = 'damage' | 'wear' | 'completeness' | 'cleanliness' | 'packaging';

export interface ConditionAssessment {
  overallQualityScore: number;
  categoryScores: CategoryScore[];
  issues: DetectedIssue[];
  confidence: number;
  analysisTimestamp: string;
}

export interface CategoryScore {
  category: ConditionCategory;
  score: number;
  notes?: string;
}

export interface DetectedIssue {
  id: string;
  category: ConditionCategory;
  severity: 'minor' | 'moderate' | 'major' | 'critical';
  description: string;
  location?: string;
}

export interface RefundDecision {
  decision: RefundType;
  refundAmount: number;
  originalAmount: number;
  restockingFee?: number;
  explanation: string;
  policyViolations: string[];
  alternativeOptions: RefundOption[];
}

export type RefundType = 'full_refund' | 'partial_refund' | 'exchange_only' | 'store_credit_only' | 'denied';

export interface RefundOption {
  id: string;
  type: 'refund_to_original' | 'store_credit' | 'exchange' | 'partial_refund';
  amount: number;
  bonusAmount?: number;
  description: string;
}

export type ReturnCaseStatus = 'created' | 'evidence' | 'assessed' | 'decided' | 'executed';

export interface ReturnCase {
  id: string;
  merchantId: string;
  orderId: string;
  itemId: string;
  reason: string;
  notes?: string;
  status: ReturnCaseStatus;
  assessment?: ConditionAssessment;
  decision?: RefundDecision;
  createdAt: string;
  updatedAt: string;
}

export interface SignedUploadParams {
  cloudName: string;
  uploadPreset: string;
  signature?: string;
  timestamp: number;
  apiKey?: string;
}
