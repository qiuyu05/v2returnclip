import Foundation

/// Handles policy reasoning via Google Gemini REST API
class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey = APIKeys.geminiApiKey
    private let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    private init() {}
    
    // MARK: - Analyze Return Eligibility
    
    /// Uses Gemini to reason about condition vs policy and determine refund
    func analyzeReturnEligibility(
        order: Order,
        item: LineItem,
        reason: ReturnReason,
        policy: ReturnPolicy,
        cloudinaryAnalysis: CloudinaryAnalysisResult
    ) async throws -> RefundDecision {
        
        let prompt = buildAnalysisPrompt(
            order: order,
            item: item,
            reason: reason,
            policy: policy,
            analysis: cloudinaryAnalysis
        )
        
        let request = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: prompt)]
                )
            ],
            generationConfig: GenerationConfig(
                responseMimeType: "application/json",
                temperature: 0.2
            )
        )
        
        var urlRequest = URLRequest(url: URL(string: "\(baseUrl)?key=\(apiKey)")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GeminiError.requestFailed
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }
        
        let decision = try JSONDecoder().decode(RefundDecision.self, from: jsonData)
        return decision
    }
    
    // MARK: - Build Prompt
    
    private func buildAnalysisPrompt(
        order: Order,
        item: LineItem,
        reason: ReturnReason,
        policy: ReturnPolicy,
        analysis: CloudinaryAnalysisResult
    ) -> String {
        """
        You are a return policy enforcement AI. Analyze the following return request and determine the appropriate refund.
        
        ## ORDER DETAILS
        - Order ID: \(order.orderNumber)
        - Purchase Date: \(order.formattedDate)
        - Days Since Purchase: \(order.daysSincePurchase)
        - Item: \(item.displayTitle)
        - Price: $\(item.price)
        
        ## RETURN REASON
        \(reason.displayName)
        
        ## RETURN POLICY
        - Merchant: \(policy.merchantName)
        - Return Window: \(policy.returnWindowDays) days
        - Restocking Fee Threshold: \(policy.restockingFeeThreshold)% quality score
        - Restocking Fee: \(policy.restockingFeePercent)%
        - Exchanges Allowed: \(policy.allowExchange)
        - Store Credit Allowed: \(policy.allowStoreCredit)
        - Store Credit Bonus: \(policy.storeCreditBonus != nil ? "\(policy.storeCreditBonus!)%" : "None")
        
        ## CONDITION REQUIREMENTS
        \(policy.conditionRequirements.map { "- \($0.category.displayName): max \($0.maxAllowedScore)% issues allowed (\($0.description))" }.joined(separator: "\n"))
        
        ## AI CONDITION ANALYSIS
        Detected features from image analysis:
        \(analysis.detectedFeatures.map { "- \($0.type): \(Int($0.confidence * 100))% detected" }.joined(separator: "\n"))
        
        Image quality: Sharpness \(Int(analysis.qualityMetrics.sharpness * 100))%, Brightness \(Int(analysis.qualityMetrics.brightness * 100))%
        
        ## INSTRUCTIONS
        Based on the above information, determine:
        1. Is the return within the allowed window?
        2. Does the item condition meet policy requirements?
        3. What refund options should be offered?
        4. Calculate exact refund amounts including any fees
        
        Respond with a JSON object in this exact format:
        {
            "decision": "full_refund" | "partial_refund" | "exchange_only" | "store_credit_only" | "denied",
            "refundAmount": <number>,
            "originalAmount": <number>,
            "restockingFee": <number or null>,
            "explanation": "<clear explanation for customer>",
            "policyViolations": ["<list of any policy violations>"],
            "alternativeOptions": [
                {
                    "id": "<unique_id>",
                    "type": "refund_to_original" | "store_credit" | "exchange" | "partial_refund",
                    "amount": <number>,
                    "bonusAmount": <number or null>,
                    "description": "<description of this option>"
                }
            ]
        }
        """
    }
}

// MARK: - Request/Response Models

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GenerationConfig: Codable {
    let responseMimeType: String
    let temperature: Double
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

enum GeminiError: Error, LocalizedError {
    case requestFailed
    case invalidResponse
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .requestFailed: return "Failed to process request"
        case .invalidResponse: return "Invalid response from AI"
        case .quotaExceeded: return "API quota exceeded"
        }
    }
}
