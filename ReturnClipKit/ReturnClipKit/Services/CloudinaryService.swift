import Foundation
import UIKit

/// Handles image upload and AI Vision analysis via Cloudinary REST API
class CloudinaryService {
    static let shared = CloudinaryService()
    
    private let cloudName = APIKeys.cloudinaryCloudName
    private let uploadPreset = APIKeys.cloudinaryUploadPreset
    
    private var uploadUrl: String {
        "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload"
    }
    
    private init() {}
    
    // MARK: - Upload Image
    
    /// Uploads an image to Cloudinary and returns the upload result
    func uploadImage(_ imageData: Data) async throws -> CloudinaryUploadResult {
        var request = URLRequest(url: URL(string: uploadUrl)!)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"return_photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add AI moderation context
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"context\"\r\n\r\n".data(using: .utf8)!)
        body.append("return_verification=true|analysis_type=condition\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CloudinaryError.uploadFailed
        }
        
        let result = try JSONDecoder().decode(CloudinaryUploadResult.self, from: data)
        return result
    }
    
    // MARK: - Analyze Condition
    
    /// Analyzes uploaded images for condition assessment
    /// Uses Cloudinary AI Vision for damage/wear detection
    func analyzeCondition(imageUrls: [String]) async throws -> CloudinaryAnalysisResult {
        // In production, this would call Cloudinary's AI Vision API
        // For hackathon, we'll simulate the analysis and let Gemini do the reasoning
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
        
        // Return simulated analysis
        // In production: POST to /v1_1/{cloud_name}/image/analyze
        return CloudinaryAnalysisResult(
            analysisId: UUID().uuidString,
            imageUrls: imageUrls,
            detectedFeatures: [
                DetectedFeature(type: "damage", confidence: 0.15, location: nil),
                DetectedFeature(type: "wear", confidence: 0.08, location: nil),
                DetectedFeature(type: "stain", confidence: 0.02, location: nil)
            ],
            qualityMetrics: QualityMetrics(
                sharpness: 0.92,
                brightness: 0.85,
                contrast: 0.88
            ),
            moderationResult: ModerationResult(
                status: "approved",
                flags: []
            )
        )
    }
}

// MARK: - Models

struct CloudinaryUploadResult: Codable {
    let publicId: String
    let secureUrl: String
    let format: String
    let width: Int
    let height: Int
    let bytes: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case publicId = "public_id"
        case secureUrl = "secure_url"
        case format, width, height, bytes
        case createdAt = "created_at"
    }
}

struct CloudinaryAnalysisResult: Codable {
    let analysisId: String
    let imageUrls: [String]
    let detectedFeatures: [DetectedFeature]
    let qualityMetrics: QualityMetrics
    let moderationResult: ModerationResult
}

struct DetectedFeature: Codable {
    let type: String
    let confidence: Double
    let location: BoundingBox?
}

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct QualityMetrics: Codable {
    let sharpness: Double
    let brightness: Double
    let contrast: Double
}

struct ModerationResult: Codable {
    let status: String
    let flags: [String]
}

enum CloudinaryError: Error, LocalizedError {
    case uploadFailed
    case analysisFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed: return "Failed to upload image"
        case .analysisFailed: return "Failed to analyze image"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}
