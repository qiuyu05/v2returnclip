import Foundation

/// Mock data for development and hackathon demo
enum MockData {
    
    // MARK: - Sample Orders
    
    static let sampleOrder = Order(
        id: "order_12345",
        orderNumber: "#RC-2026-12345",
        purchaseDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        purchaseLocation: "Toronto, ON",
        customerEmail: "customer@example.com",
        customerName: "Alex Johnson",
        lineItems: [
            LineItem(
                id: "item_001",
                productId: "prod_velvet_chair",
                variantId: "var_navy",
                title: "Velvet Accent Chair",
                variantTitle: "Navy Blue",
                sku: "CHAIR-VLV-NAVY-001",
                quantity: 1,
                price: 299.00,
                imageUrl: "https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?w=400"
            ),
            LineItem(
                id: "item_002",
                productId: "prod_throw_pillow",
                variantId: "var_cream",
                title: "Luxury Throw Pillow Set",
                variantTitle: "Cream - Set of 2",
                sku: "PILLOW-LUX-CRM-002",
                quantity: 1,
                price: 79.00,
                imageUrl: "https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=400"
            )
        ],
        totalPrice: 378.00,
        currency: "CAD",
        paymentMethod: PaymentMethod(type: .card, lastFour: "4242", brand: "Visa")
    )
    
    static let furnitureOrder = Order(
        id: "order_67890",
        orderNumber: "#RC-2026-67890",
        purchaseDate: Calendar.current.date(byAdding: .day, value: -12, to: Date())!,
        purchaseLocation: "Vancouver, BC",
        customerEmail: "furniture.lover@example.com",
        customerName: "Sam Chen",
        lineItems: [
            LineItem(
                id: "item_003",
                productId: "prod_sectional",
                variantId: "var_gray",
                title: "Milano Sectional Sofa",
                variantTitle: "Charcoal Gray - Left Facing",
                sku: "SOFA-MIL-GRY-L",
                quantity: 1,
                price: 1899.00,
                imageUrl: "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400"
            )
        ],
        totalPrice: 1899.00,
        currency: "CAD",
        paymentMethod: PaymentMethod(type: .applePay, lastFour: nil, brand: nil)
    )
    
    // MARK: - Sample Policies
    
    static let furnitureReturnPolicy = ReturnPolicy(
        id: "policy_furniture",
        merchantName: "Refined Concept",
        returnWindowDays: 30,
        conditionRequirements: [
            ConditionRequirement(
                category: .damage,
                maxAllowedScore: 10,
                description: "No scratches, dents, or tears"
            ),
            ConditionRequirement(
                category: .wear,
                maxAllowedScore: 15,
                description: "Minimal signs of use"
            ),
            ConditionRequirement(
                category: .cleanliness,
                maxAllowedScore: 5,
                description: "No stains or odors"
            ),
            ConditionRequirement(
                category: .completeness,
                maxAllowedScore: 0,
                description: "All parts and hardware included"
            )
        ],
        restockingFeeThreshold: 85,
        restockingFeePercent: 20,
        allowExchange: true,
        allowStoreCredit: true,
        storeCreditBonus: 0.10,
        requiresPhotos: true,
        requiresVideo: false,
        demoVideoUrl: "https://example.com/return-demo.mp4",
        shippingPaidBy: .merchant,
        processingDays: 5
    )
    
    static let electronicsReturnPolicy = ReturnPolicy(
        id: "policy_electronics",
        merchantName: "TechShop",
        returnWindowDays: 14,
        conditionRequirements: [
            ConditionRequirement(
                category: .damage,
                maxAllowedScore: 5,
                description: "No physical damage"
            ),
            ConditionRequirement(
                category: .packaging,
                maxAllowedScore: 20,
                description: "Original packaging preferred"
            )
        ],
        restockingFeeThreshold: 90,
        restockingFeePercent: 15,
        allowExchange: true,
        allowStoreCredit: true,
        storeCreditBonus: nil,
        requiresPhotos: true,
        requiresVideo: false,
        demoVideoUrl: nil,
        shippingPaidBy: .customer,
        processingDays: 3
    )
    
    // MARK: - Sample Analysis Results
    
    static let excellentConditionAssessment = ConditionAssessment(
        overallQualityScore: 95,
        categoryScores: [
            CategoryScore(category: .damage, score: 98, notes: "No visible damage"),
            CategoryScore(category: .wear, score: 95, notes: "Appears unused"),
            CategoryScore(category: .cleanliness, score: 97, notes: "Clean condition"),
            CategoryScore(category: .completeness, score: 100, notes: "All items present")
        ],
        issues: [],
        confidence: 0.94,
        analysisTimestamp: Date()
    )
    
    static let fairConditionAssessment = ConditionAssessment(
        overallQualityScore: 72,
        categoryScores: [
            CategoryScore(category: .damage, score: 85, notes: "Minor scratch on leg"),
            CategoryScore(category: .wear, score: 65, notes: "Visible use on cushion"),
            CategoryScore(category: .cleanliness, score: 70, notes: "Light staining"),
            CategoryScore(category: .completeness, score: 100, notes: "All items present")
        ],
        issues: [
            DetectedIssue(
                id: "issue_1",
                category: .damage,
                severity: .minor,
                description: "Small scratch approximately 2cm",
                location: "Front left leg"
            ),
            DetectedIssue(
                id: "issue_2",
                category: .wear,
                severity: .moderate,
                description: "Compression marks on seat cushion",
                location: "Center seat"
            )
        ],
        confidence: 0.88,
        analysisTimestamp: Date()
    )
    
    // MARK: - Sample Refund Decisions
    
    static let fullRefundDecision = RefundDecision(
        decision: .fullRefund,
        refundAmount: 299.00,
        originalAmount: 299.00,
        restockingFee: nil,
        explanation: "Item is in excellent condition within the 30-day return window. Full refund approved.",
        policyViolations: [],
        alternativeOptions: [
            RefundOption(
                id: "opt_1",
                type: .refundToOriginal,
                amount: 299.00,
                bonusAmount: nil,
                description: "Full refund to Visa ****4242"
            ),
            RefundOption(
                id: "opt_2",
                type: .storeCredit,
                amount: 299.00,
                bonusAmount: 29.90,
                description: "Store credit with 10% bonus ($328.90 total)"
            ),
            RefundOption(
                id: "opt_3",
                type: .exchange,
                amount: 299.00,
                bonusAmount: nil,
                description: "Exchange for different color/size"
            )
        ]
    )
    
    static let partialRefundDecision = RefundDecision(
        decision: .partialRefund,
        refundAmount: 239.20,
        originalAmount: 299.00,
        restockingFee: 59.80,
        explanation: "Item shows signs of use. A 20% restocking fee applies per our return policy.",
        policyViolations: [
            "Item condition score (72%) below threshold (85%)"
        ],
        alternativeOptions: [
            RefundOption(
                id: "opt_1",
                type: .partialRefund,
                amount: 239.20,
                bonusAmount: nil,
                description: "Partial refund to Visa ****4242 (20% restocking fee)"
            ),
            RefundOption(
                id: "opt_2",
                type: .storeCredit,
                amount: 269.10,
                bonusAmount: 29.90,
                description: "Store credit with 10% bonus (reduced restocking fee)"
            )
        ]
    )
    
    // MARK: - Helper
    
    static func getOrder(for orderId: String) -> Order? {
        switch orderId {
        case "12345", "order_12345":
            return sampleOrder
        case "67890", "order_67890":
            return furnitureOrder
        default:
            return sampleOrder  // Default to sample for demo
        }
    }
    
    static func getPolicy(for merchantId: String) -> ReturnPolicy {
        return furnitureReturnPolicy  // Default for demo
    }
}
