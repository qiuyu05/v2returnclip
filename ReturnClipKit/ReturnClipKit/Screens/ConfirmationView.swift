import SwiftUI
import CoreImage.CIFilterBuiltins

/// Screen 6: Return confirmation with label and instructions
struct ConfirmationView: View {
    @ObservedObject var flowState: ReturnFlowState
    @State private var showingShareSheet = false
    @State private var showSuccess = false
    @State private var showCelebration = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: RCSpacing.xl) {
                // Celebration particles
                if showCelebration {
                    CelebrationView()
                        .frame(height: 0) // overlay only
                }
                
                // Success header
                successHeader
                    .slideIn(delay: 0.1)
                
                // Return label QR code
                returnLabelSection
                    .slideIn(delay: 0.3)
                
                // Instructions
                instructionsSection
                    .slideIn(delay: 0.4)
                
                // Timeline
                timelineSection
                    .slideIn(delay: 0.5)
                
                // Actions
                actionsSection
                    .slideIn(delay: 0.6)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, RCSpacing.lg)
            .padding(.top, RCSpacing.sm)
        }
        .background(Color.rcSurface)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    showSuccess = true
                    showCelebration = true
                }
                RCHaptics.success()
            }
        }
    }
    
    // MARK: - Components
    
    private var successHeader: some View {
        VStack(spacing: RCSpacing.lg) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(Color.rcSuccess.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showSuccess ? 1.2 : 0.8)
                    .opacity(showSuccess ? 0.6 : 0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showSuccess)
                
                // Inner glow
                Circle()
                    .fill(Color.rcSuccess.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(LinearGradient.rcSuccess)
                    .scaleEffect(showSuccess ? 1.0 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.4), value: showSuccess)
            }
            
            Text("Return Approved!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            if let option = flowState.selectedRefundOption {
                HStack(spacing: RCSpacing.sm) {
                    Text("$\((option.amount + (option.bonusAmount ?? 0)).currencyString)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.rcSuccess)
                    
                    Text(refundTypeText(option.type))
                        .font(.system(size: 15))
                        .foregroundColor(.rcTextSecondary)
                }
            }
        }
        .padding(.top, RCSpacing.lg)
    }
    
    private var returnLabelSection: some View {
        VStack(spacing: RCSpacing.lg) {
            Text("Return Label")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            // QR Code with styled frame
            VStack(spacing: RCSpacing.md) {
                if let qrImage = generateQRCode(from: "RETURN-\(flowState.order?.orderNumber ?? "12345")") {
                    ZStack {
                        RoundedRectangle(cornerRadius: RCRadius.lg)
                            .fill(Color.white)
                            .frame(width: 210, height: 210)
                            .rcShadowElevated()
                        
                        RoundedRectangle(cornerRadius: RCRadius.md)
                            .stroke(
                                LinearGradient(
                                    colors: [.rcPrimary.opacity(0.3), .rcPrimaryLight.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 210, height: 210)
                        
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 170)
                    }
                }
                
                Text("Show this code at drop-off")
                    .font(.system(size: 13))
                    .foregroundColor(.rcTextSecondary)
            }
            
            // Return ID — copyable
            HStack(spacing: RCSpacing.sm) {
                Text("Return ID:")
                    .font(.system(size: 13))
                    .foregroundColor(.rcTextSecondary)
                
                Text("RTN-\(String(flowState.order?.orderNumber.suffix(8) ?? "00000000"))")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.rcTextPrimary)
                
                Button {
                    RCHaptics.impact(.light)
                    UIPasteboard.general.string = "RTN-\(String(flowState.order?.orderNumber.suffix(8) ?? "00000000"))"
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundColor(.rcPrimary)
                        .padding(RCSpacing.sm)
                        .background(Color.rcPrimary.opacity(0.1))
                        .cornerRadius(RCRadius.sm)
                }
            }
        }
        .rcCard()
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: RCSpacing.lg) {
            Text("Next Steps")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            InstructionRow(
                number: "1",
                title: "Pack your item",
                description: "Use original packaging if available"
            )
            
            InstructionRow(
                number: "2",
                title: "Drop off at Canada Post",
                description: "Find nearest location below"
            )
            
            InstructionRow(
                number: "3",
                title: "Show QR code",
                description: "No printing required"
            )
            
            // Nearest location
            Button {
                RCHaptics.impact(.light)
                if let url = URL(string: "maps://?q=Canada+Post") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: RCSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.rcPrimary.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.rcPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Find Nearest Drop-off")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.rcTextPrimary)
                        Text("Canada Post locations")
                            .font(.system(size: 12))
                            .foregroundColor(.rcTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.rcTextMuted)
                }
                .padding(RCSpacing.lg)
                .background(Color.rcSurfaceElevated)
                .cornerRadius(RCRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: RCRadius.lg)
                        .stroke(Color.rcBorder.opacity(0.6), lineWidth: 1)
                )
            }
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Timeline")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
                .padding(.bottom, RCSpacing.lg)
            
            TimelineRow(
                icon: "shippingbox",
                title: "Drop off item",
                subtitle: "Within 7 days",
                isComplete: false,
                isLast: false
            )
            
            TimelineRow(
                icon: "building.2",
                title: "Item received",
                subtitle: "1-3 business days after drop-off",
                isComplete: false,
                isLast: false
            )
            
            TimelineRow(
                icon: "checkmark.circle",
                title: "Refund processed",
                subtitle: "\(flowState.policy?.processingDays ?? 5) business days",
                isComplete: false,
                isLast: true
            )
        }
        .rcCard()
    }
    
    private var actionsSection: some View {
        VStack(spacing: RCSpacing.md) {
            Button {
                RCHaptics.impact(.medium)
                showingShareSheet = true
            } label: {
                HStack(spacing: RCSpacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Return Details")
                }
            }
            .buttonStyle(RCPrimaryButtonStyle())
            
            Button {
                RCHaptics.impact(.light)
            } label: {
                HStack(spacing: RCSpacing.sm) {
                    Image(systemName: "wallet.pass.fill")
                    Text("Add to Apple Wallet")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(RCRadius.lg)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func refundTypeText(_ type: RefundOptionType) -> String {
        switch type {
        case .refundToOriginal: return "to your card"
        case .storeCredit: return "store credit"
        case .exchange: return "exchange"
        case .partialRefund: return "partial refund"
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = 10.0
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: RCSpacing.lg) {
            ZStack {
                Circle()
                    .fill(LinearGradient.rcPrimary)
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.rcTextPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.rcTextSecondary)
            }
        }
    }
}

struct TimelineRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isComplete: Bool
    var isLast: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: RCSpacing.lg) {
            // Vertical line + icon
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isComplete ? Color.rcSuccess.opacity(0.12) : Color.rcSurfaceMuted)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(isComplete ? Color.rcSuccess.opacity(0.3) : Color.rcBorder, lineWidth: 1.5)
                        )
                    
                    Image(systemName: isComplete ? "checkmark" : icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isComplete ? .rcSuccess : .rcTextMuted)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.rcBorder)
                        .frame(width: 2, height: 32)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.rcTextPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.rcTextSecondary)
            }
            .padding(.top, 6)
            
            Spacer()
            
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.rcSuccess)
                    .font(.system(size: 18))
                    .padding(.top, 6)
            }
        }
    }
}
