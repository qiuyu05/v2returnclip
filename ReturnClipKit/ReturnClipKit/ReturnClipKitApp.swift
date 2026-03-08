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
                    if let id = parseOrderId(from: url) {
                        orderId = id
                    }
                }
        }
    }

    private func parseOrderId(from url: URL) -> String? {
        let components = url.pathComponents
        if let returnIndex = components.firstIndex(of: "return"),
           returnIndex + 1 < components.count {
            return components[returnIndex + 1]
        }
        return components.last
    }
}

// MARK: - Clip Experience Protocol Conformance

extension ReturnClipExperience {
    static let urlPattern = "returnclip.app/return/:orderId"
    static let clipName = "ReturnClip"
    static let clipDescription = "AI-powered returns verification for Shopify merchants"
    static let teamName = "Team ReturnClip"
    static let touchpoint = "Post-purchase (8 hours after delivery)"
    static let invocationSource = "Push notification / QR code on packaging"
}
