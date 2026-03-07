import Foundation

/// Merchant's return policy configuration
struct ReturnPolicy: Codable {
    let id: String
    let merchantName: String
    let returnWindowDays: Int
    let conditionRequirements: [ConditionRequirement]
    let restockingFeeThreshold: Int  // Quality score below this triggers fee
    let restockingFeePercent: Decimal
    let allowExchange: Bool
    let allowStoreCredit: Bool
    let storeCreditBonus: Decimal?  // e.g., 0.10 for 10% bonus
    let requiresPhotos: Bool
    let requiresVideo: Bool
    let demoVideoUrl: String?
    let shippingPaidBy: ShippingPaidBy
    let processingDays: Int
    
    func isWithinReturnWindow(daysSincePurchase: Int) -> Bool {
        daysSincePurchase <= returnWindowDays
    }
    
    func daysRemaining(daysSincePurchase: Int) -> Int {
        max(0, returnWindowDays - daysSincePurchase)
    }
}

struct ConditionRequirement: Codable {
    let category: ConditionCategory
    let maxAllowedScore: Int  // 0-100, higher = more damage allowed
    let description: String
}

enum ConditionCategory: String, Codable, CaseIterable {
    case damage = "damage"
    case wear = "wear"
    case completeness = "completeness"
    case cleanliness = "cleanliness"
    case packaging = "packaging"
    
    var displayName: String {
        switch self {
        case .damage: return "Physical Damage"
        case .wear: return "Signs of Use"
        case .completeness: return "All Parts Included"
        case .cleanliness: return "Cleanliness"
        case .packaging: return "Original Packaging"
        }
    }
    
    var icon: String {
        switch self {
        case .damage: return "exclamationmark.triangle"
        case .wear: return "clock.arrow.circlepath"
        case .completeness: return "checkmark.circle"
        case .cleanliness: return "sparkles"
        case .packaging: return "shippingbox"
        }
    }
}

enum ShippingPaidBy: String, Codable {
    case merchant
    case customer
    case split
}
