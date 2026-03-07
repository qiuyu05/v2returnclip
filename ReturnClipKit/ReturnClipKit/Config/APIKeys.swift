import Foundation

/// API Keys for ReturnClip services
/// 
/// For demo mode, these placeholder values work fine — the app
/// falls back to mock data when API calls fail.
///
/// To use real APIs, replace with your actual keys:
/// - Cloudinary: https://cloudinary.com (free tier)
/// - Gemini: https://ai.google.dev (free tier)
enum APIKeys {
    static let cloudinaryCloudName = "demo_cloud"
    static let cloudinaryUploadPreset = "demo_preset"
    static let geminiApiKey = "demo_key"
    static let shopifyStoreDomain = "demo-store.myshopify.com"
    static let shopifyStorefrontToken = "demo_token"
    
    static var isConfigured: Bool {
        cloudinaryCloudName != "demo_cloud"
    }
}
