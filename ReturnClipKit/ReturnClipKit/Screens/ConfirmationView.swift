import SwiftUI
import CoreImage.CIFilterBuiltins

/// Screen 6: Return confirmation with label and instructions
struct ConfirmationView: View {
    @ObservedObject var flowState: ReturnFlowState
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success header
                successHeader
                
                // Return label QR code
                returnLabelSection
                
                // Instructions
                instructionsSection
                
                // Timeline
                timelineSection
                
                // Actions
                actionsSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Components
    
    private var successHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            Text("Return Approved!")
                .font(.title)
                .fontWeight(.bold)
            
            if let option = flowState.selectedRefundOption {
                Text("$\(option.amount + (option.bonusAmount ?? 0), specifier: "%.2f") \(refundTypeText(option.type))")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top)
    }
    
    private var returnLabelSection: some View {
        VStack(spacing: 16) {
            Text("Return Label")
                .font(.headline)
            
            // QR Code
            if let qrImage = generateQRCode(from: "RETURN-\(flowState.order?.orderNumber ?? "12345")") {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
            
            Text("Show this code at drop-off")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Return ID
            HStack {
                Text("Return ID:")
                    .foregroundColor(.secondary)
                Text("RTN-\(String(flowState.order?.orderNumber.suffix(8) ?? "00000000"))")
                    .fontWeight(.mono)
                
                Button {
                    UIPasteboard.general.string = "RTN-\(String(flowState.order?.orderNumber.suffix(8) ?? "00000000"))"
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Steps")
                .font(.headline)
            
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
                // Open maps
                if let url = URL(string: "maps://?q=Canada+Post") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Find Nearest Drop-off")
                            .fontWeight(.medium)
                        Text("Canada Post locations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.primary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            
            TimelineRow(
                icon: "shippingbox",
                title: "Drop off item",
                subtitle: "Within 7 days",
                isComplete: false
            )
            
            TimelineRow(
                icon: "building.2",
                title: "Item received",
                subtitle: "1-3 business days after drop-off",
                isComplete: false
            )
            
            TimelineRow(
                icon: "checkmark.circle",
                title: "Refund processed",
                subtitle: "\(flowState.policy?.processingDays ?? 5) business days",
                isComplete: false
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Return Details")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button {
                // Add to wallet
            } label: {
                HStack {
                    Image(systemName: "wallet.pass")
                    Text("Add to Apple Wallet")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
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
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TimelineRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isComplete ? .green : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}
