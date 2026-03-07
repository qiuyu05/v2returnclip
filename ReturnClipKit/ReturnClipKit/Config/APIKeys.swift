import Foundation

/// API Keys Configuration
/// ⚠️ Replace these with your actual API keys before running
enum APIKeys {
    // MARK: - Cloudinary
    /// Get from: https://cloudinary.com/console
    static let cloudinaryCloudName = "YOUR_CLOUD_NAME"
    
    /// Create unsigned upload preset in Cloudinary Console:
    /// Settings > Upload > Upload presets > Add unsigned preset
    static let cloudinaryUploadPreset = "YOUR_UPLOAD_PRESET"
    
    // MARK: - Google Gemini
    /// Get from: https://ai.google.dev/
    static let geminiApiKey = "YOUR_GEMINI_API_KEY"
    
    // MARK: - Shopify (Optional)
    /// Only needed if connecting to real Shopify store
    static let shopifyStoreDomain = "your-store.myshopify.com"
    static let shopifyStorefrontToken = "YOUR_STOREFRONT_TOKEN"
    
    // MARK: - Validation
    static var isConfigured: Bool {
        cloudinaryCloudName != "YOUR_CLOUD_NAME" &&
        cloudinaryUploadPreset != "YOUR_UPLOAD_PRESET" &&
        geminiApiKey != "YOUR_GEMINI_API_KEY"
    }
}
