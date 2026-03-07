import SwiftUI

/// Main entry point for ReturnClip
/// 
/// URL Pattern: returnclip.app/return/:orderId
/// 
/// Example invocations:
/// - returnclip.app/return/12345
/// - returnclip.app/return/67890
///
@main
struct ReturnClipKitApp: App {
    @State private var orderId: String = "12345"
    
    var body: some Scene {
        WindowGroup {
            ReturnClipExperience(orderId: orderId)
                .onOpenURL { url in
                    // Parse order ID from URL
                    if let id = parseOrderId(from: url) {
                        orderId = id
                    }
                }
        }
    }
    
    /// Parses order ID from clip invocation URL
    /// Expected format: returnclip.app/return/{orderId}
    private func parseOrderId(from url: URL) -> String? {
        let components = url.pathComponents
        
        // Look for /return/{orderId} pattern
        if let returnIndex = components.firstIndex(of: "return"),
           returnIndex + 1 < components.count {
            return components[returnIndex + 1]
        }
        
        // Fallback: use last path component
        return components.last
    }
}

// MARK: - Clip Experience Protocol Conformance
// For integration with Reactiv ClipKit Lab

extension ReturnClipExperience {
    /// URL pattern for clip invocation
    static let urlPattern = "returnclip.app/return/:orderId"
    
    /// Clip display name
    static let clipName = "ReturnClip"
    
    /// Clip description
    static let clipDescription = "AI-powered returns verification for Shopify merchants"
    
    /// Team name
    static let teamName = "Team ReturnClip"
    
    /// Customer journey touchpoint
    static let touchpoint = "Post-purchase (8 hours after delivery)"
    
    /// How the clip is invoked
    static let invocationSource = "Push notification / QR code on packaging"
}
