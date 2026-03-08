import Foundation

/// Communicates with the ReturnClip Next.js backend.
/// Return flow: orders/lookup → returns/create → evidence → assess → decide → execute
class BackendService {
    static let shared = BackendService()

    private let baseUrl = APIKeys.backendUrl
    private let merchantId = "refined_concept"

    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        // Backend sends fractional seconds (e.g. "2026-03-03T01:37:51.101Z")
        // .iso8601 doesn't support fractional seconds — use custom formatter
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = formatter.date(from: str) { return date }
            // fallback without fractional seconds
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }()

    private init() {}

    // MARK: - Order Lookup

    /// Look up an order by order number (falls back to mock data on backend if Shopify not configured).
    func lookupOrder(orderNumber: String, email: String = "") async throws -> OrderLookupResponse {
        guard let url = URL(string: "\(baseUrl)/api/orders/lookup") else {
            throw BackendError.invalidUrl
        }
        let body = OrderLookupRequest(merchantId: merchantId, orderNumber: orderNumber, email: email)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendError.requestFailed
        }
        return try decoder.decode(OrderLookupResponse.self, from: data)
    }

    // MARK: - Return Case: Create

    /// Creates a new return case on the backend. Returns the caseId.
    func createCase(orderId: String, itemId: String, reason: String, notes: String = "") async throws -> String {
        guard let url = URL(string: "\(baseUrl)/api/returns/create") else {
            throw BackendError.invalidUrl
        }
        let body = CreateCaseRequest(orderId: orderId, itemId: itemId, reason: reason, notes: notes)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendError.requestFailed
        }
        return try decoder.decode(CreateCaseResponse.self, from: data).caseId
    }

    // MARK: - Return Case: Submit Evidence

    /// Submits Cloudinary image URLs as evidence for the return case.
    func submitEvidence(caseId: String, imageUrls: [String]) async throws {
        guard let url = URL(string: "\(baseUrl)/api/returns/\(caseId)/evidence") else {
            throw BackendError.invalidUrl
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(EvidenceRequest(imageUrls: imageUrls))
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendError.requestFailed
        }
    }

    // MARK: - Return Case: AI Condition Assessment

    /// Runs Gemini Vision on the submitted evidence. Returns ConditionAssessment.
    func assessCondition(caseId: String) async throws -> ConditionAssessment {
        guard let url = URL(string: "\(baseUrl)/api/returns/\(caseId)/assess") else {
            throw BackendError.invalidUrl
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(EmptyBody())
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendError.requestFailed
        }
        return try decoder.decode(AssessResponse.self, from: data).assessment
    }

    // MARK: - Return Case: Refund Decision

    /// Asks the backend for a refund decision based on the assessment + policy.
    func getRefundDecision(caseId: String) async throws -> RefundDecision {
        guard let url = URL(string: "\(baseUrl)/api/returns/\(caseId)/decide") else {
            throw BackendError.invalidUrl
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(EmptyBody())
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendError.requestFailed
        }
        return try decoder.decode(DecideResponse.self, from: data).decision
    }

    // MARK: - Return Case: Execute

    /// Executes the selected refund option. Idempotent — safe to retry.
    func executeReturn(
        caseId: String,
        selectedOptionId: String,
        exchangeProductTitle: String? = nil,
        exchangeVariantTitle: String? = nil,
        exchangePrice: Double? = nil
    ) async throws -> ExecuteResponse {
        guard let url = URL(string: "\(baseUrl)/api/returns/\(caseId)/execute") else {
            throw BackendError.invalidUrl
        }
        let body = ExecuteRequest(
            selectedOptionId: selectedOptionId,
            idempotencyKey: UUID().uuidString,
            exchangeProductTitle: exchangeProductTitle,
            exchangeVariantTitle: exchangeVariantTitle,
            exchangePrice: exchangePrice
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BackendError.requestFailed
        }
        return try decoder.decode(ExecuteResponse.self, from: data)
    }

    // MARK: - Exchange Products

    /// Fetches exchange products from backend (which pulls from Shopify if configured).
    /// Falls back to embedded mock products if backend is unreachable.
    func fetchProducts(limit: Int = 20) async throws -> [ShopifyProduct] {
        guard let url = URL(string: "\(baseUrl)/api/products?limit=\(limit)") else {
            return mockExchangeProducts
        }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return mockExchangeProducts
            }
            let products = try decoder.decode(ShopifyProductsResponse.self, from: data).products
            return products.isEmpty ? mockExchangeProducts : products
        } catch {
            return mockExchangeProducts
        }
    }

    // MARK: - Health Check

    func isReachable() async -> Bool {
        guard let url = URL(string: "\(baseUrl)/api/orders/lookup") else { return false }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 5
            request.httpBody = try? JSONEncoder().encode(["merchantId": "ping", "orderNumber": "ping"])
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse) != nil
        } catch {
            return false
        }
    }
}

// MARK: - Request Models

struct OrderLookupRequest: Codable {
    let merchantId: String
    let orderNumber: String
    let email: String
}

struct CreateCaseRequest: Codable {
    let orderId: String
    let itemId: String
    let reason: String
    let notes: String
}

struct EvidenceRequest: Codable {
    let imageUrls: [String]
}

struct ExecuteRequest: Codable {
    let selectedOptionId: String
    let idempotencyKey: String
    let exchangeProductTitle: String?
    let exchangeVariantTitle: String?
    let exchangePrice: Double?
}

struct EmptyBody: Codable {}

// MARK: - Response Models

struct OrderLookupResponse: Codable {
    let order: Order
    let policy: ReturnPolicy
    let eligible: Bool
}

struct CreateCaseResponse: Codable {
    let caseId: String
    let status: String
}

struct AssessResponse: Codable {
    let assessment: ConditionAssessment
}

struct DecideResponse: Codable {
    let decision: RefundDecision
}

struct ExecuteResponse: Codable {
    let executionId: String
    let status: String
    let refundAmount: Double?
}

// MARK: - Shopify Product Models (used by ExchangeProductsView)

struct ShopifyProductsResponse: Codable {
    let products: [ShopifyProduct]
}

struct ShopifyProduct: Codable, Identifiable {
    let id: String
    let title: String
    let handle: String
    let description: String?
    let minPrice: Double
    let currency: String
    let imageUrl: String?
    let variants: [ShopifyVariant]

    var formattedPrice: String {
        String(format: "$%.2f %@", minPrice, currency)
    }
}

struct ShopifyVariant: Codable, Identifiable {
    let id: String
    let title: String
    let price: Double
    let availableForSale: Bool
}

// MARK: - Errors

enum BackendError: Error, LocalizedError {
    case invalidUrl
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidUrl: return "Invalid backend URL"
        case .requestFailed: return "Backend request failed"
        case .decodingFailed: return "Could not parse backend response"
        }
    }
}

// MARK: - Mock Exchange Products (embedded — new backend has no products endpoint)

private let mockExchangeProducts: [ShopifyProduct] = [
    ShopifyProduct(
        id: "prod_velvet_chair", title: "Velvet Accent Chair", handle: "velvet-accent-chair",
        description: "Luxurious velvet upholstered accent chair", minPrice: 299.0, currency: "CAD",
        imageUrl: "https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?w=400",
        variants: [
            ShopifyVariant(id: "var_navy", title: "Navy Blue", price: 299.0, availableForSale: true),
            ShopifyVariant(id: "var_blush", title: "Blush Pink", price: 299.0, availableForSale: true),
            ShopifyVariant(id: "var_forest", title: "Forest Green", price: 319.0, availableForSale: true),
        ]
    ),
    ShopifyProduct(
        id: "prod_sectional", title: "Milano Sectional Sofa", handle: "milano-sectional",
        description: "Modern modular sectional with chaise", minPrice: 1899.0, currency: "CAD",
        imageUrl: "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400",
        variants: [
            ShopifyVariant(id: "var_gray_l", title: "Charcoal Gray - Left Facing", price: 1899.0, availableForSale: true),
            ShopifyVariant(id: "var_gray_r", title: "Charcoal Gray - Right Facing", price: 1899.0, availableForSale: true),
            ShopifyVariant(id: "var_cream_l", title: "Cream - Left Facing", price: 1949.0, availableForSale: false),
        ]
    ),
    ShopifyProduct(
        id: "prod_throw_pillow", title: "Luxury Throw Pillow Set", handle: "luxury-throw-pillow",
        description: "Set of 2 premium throw pillows", minPrice: 79.0, currency: "CAD",
        imageUrl: "https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=400",
        variants: [
            ShopifyVariant(id: "var_creme", title: "Cream - Set of 2", price: 79.0, availableForSale: true),
            ShopifyVariant(id: "var_sage", title: "Sage Green - Set of 2", price: 79.0, availableForSale: true),
        ]
    ),
    ShopifyProduct(
        id: "prod_marble_table", title: "Marble Side Table", handle: "marble-side-table",
        description: "Genuine marble top with brass base", minPrice: 449.0, currency: "CAD",
        imageUrl: "https://images.unsplash.com/photo-1532372576444-dda954194ad0?w=400",
        variants: [
            ShopifyVariant(id: "var_white_marble", title: "White Marble", price: 449.0, availableForSale: true),
            ShopifyVariant(id: "var_black_marble", title: "Black Marble", price: 499.0, availableForSale: true),
        ]
    ),
    ShopifyProduct(
        id: "prod_linen_rug", title: "Natural Linen Area Rug", handle: "natural-linen-rug",
        description: "Handwoven natural linen, 5x8 ft", minPrice: 349.0, currency: "CAD",
        imageUrl: "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400",
        variants: [
            ShopifyVariant(id: "var_5x8", title: "5 x 8 ft", price: 349.0, availableForSale: true),
            ShopifyVariant(id: "var_8x10", title: "8 x 10 ft", price: 549.0, availableForSale: true),
        ]
    ),
    ShopifyProduct(
        id: "prod_ceramic_lamp", title: "Ceramic Table Lamp", handle: "ceramic-table-lamp",
        description: "Handcrafted ceramic base with linen shade", minPrice: 189.0, currency: "CAD",
        imageUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400",
        variants: [
            ShopifyVariant(id: "var_ivory", title: "Ivory", price: 189.0, availableForSale: true),
            ShopifyVariant(id: "var_terracotta", title: "Terracotta", price: 189.0, availableForSale: true),
        ]
    ),
]
