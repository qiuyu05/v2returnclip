import Foundation

/// Result of AI condition analysis from Cloudinary + Gemini
struct ConditionAssessment: Codable {
    let overallQualityScore: Int  // 0-100, higher = better condition
    let categoryScores: [CategoryScore]
    let issues: [DetectedIssue]
    let confidence: Double  // 0-1
    let analysisTimestamp: Date
    
    var qualityLevel: QualityLevel {
        switch overallQualityScore {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 50..<75: return .fair
        case 25..<50: return .poor
        default: return .unacceptable
        }
    }
}

struct CategoryScore: Codable {
    let category: ConditionCategory
    let score: Int  // 0-100
    let notes: String?
}

struct DetectedIssue: Codable, Identifiable {
    let id: String
    let category: ConditionCategory
    let severity: IssueSeverity
    let description: String
    let location: String?  // e.g., "top-left corner"
}

enum IssueSeverity: String, Codable {
    case minor
    case moderate
    case major
    case critical
    
    var color: String {
        switch self {
        case .minor: return "green"
        case .moderate: return "yellow"
        case .major: return "orange"
        case .critical: return "red"
        }
    }
}

enum QualityLevel: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case unacceptable = "Unacceptable"
    
    var emoji: String {
        switch self {
        case .excellent: return "✅"
        case .good: return "👍"
        case .fair: return "⚠️"
        case .poor: return "⛔"
        case .unacceptable: return "❌"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .unacceptable: return "red"
        }
    }
}

/// Gemini's refund decision based on condition + policy
struct RefundDecision: Codable {
    let decision: RefundType
    let refundAmount: Decimal
    let originalAmount: Decimal
    let restockingFee: Decimal?
    let explanation: String
    let policyViolations: [String]
    let alternativeOptions: [RefundOption]
}

enum RefundType: String, Codable {
    case fullRefund = "full_refund"
    case partialRefund = "partial_refund"
    case exchangeOnly = "exchange_only"
    case storeCreditOnly = "store_credit_only"
    case denied = "denied"
}

struct RefundOption: Codable, Identifiable {
    let id: String
    let type: RefundOptionType
    let amount: Decimal
    let bonusAmount: Decimal?
    let description: String
}

enum RefundOptionType: String, Codable {
    case refundToOriginal = "refund_to_original"
    case storeCredit = "store_credit"
    case exchange = "exchange"
    case partialRefund = "partial_refund"
}
