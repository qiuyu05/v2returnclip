import Foundation

/// Represents a Shopify order for return processing
struct Order: Codable, Identifiable {
    let id: String
    let orderNumber: String
    let purchaseDate: Date
    let purchaseLocation: String
    let customerEmail: String
    let customerName: String
    let lineItems: [LineItem]
    let totalPrice: Decimal
    let currency: String
    let paymentMethod: PaymentMethod
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: purchaseDate)
    }
    
    var daysSincePurchase: Int {
        Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
    }
}

struct LineItem: Codable, Identifiable {
    let id: String
    let productId: String
    let variantId: String
    let title: String
    let variantTitle: String?
    let sku: String
    let quantity: Int
    let price: Decimal
    let imageUrl: String?
    
    var displayTitle: String {
        if let variant = variantTitle, !variant.isEmpty {
            return "\(title) - \(variant)"
        }
        return title
    }
}

struct PaymentMethod: Codable {
    let type: PaymentType
    let lastFour: String?
    let brand: String?
    
    var displayName: String {
        switch type {
        case .card:
            return "\(brand ?? "Card") ****\(lastFour ?? "0000")"
        case .applePay:
            return "Apple Pay"
        case .shopPay:
            return "Shop Pay"
        case .paypal:
            return "PayPal"
        }
    }
}

enum PaymentType: String, Codable {
    case card
    case applePay
    case shopPay
    case paypal
}
