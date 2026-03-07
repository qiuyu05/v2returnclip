import SwiftUI

/// Screen 5: Choose refund option
struct RefundOptionsView: View {
    @ObservedObject var flowState: ReturnFlowState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Refund options
                if let decision = flowState.refundDecision {
                    optionsSection(decision)
                    
                    // Summary
                    summarySection(decision)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Choose Your Refund")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Select the option that works best for you")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    private func optionsSection(_ decision: RefundDecision) -> some View {
        VStack(spacing: 12) {
            ForEach(decision.alternativeOptions) { option in
                optionCard(option)
            }
        }
    }
    
    private func optionCard(_ option: RefundOption) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                flowState.selectedRefundOption = option
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Icon
                    Image(systemName: optionIcon(option.type))
                        .font(.title2)
                        .foregroundColor(flowState.selectedRefundOption?.id == option.id ? .white : .blue)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(optionTitle(option.type))
                            .font(.headline)
                            .foregroundColor(flowState.selectedRefundOption?.id == option.id ? .white : .primary)
                        
                        Text(option.description)
                            .font(.caption)
                            .foregroundColor(flowState.selectedRefundOption?.id == option.id ? .white.opacity(0.8) : .secondary)
                    }
                    
                    Spacer()
                    
                    // Amount
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(option.amount, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(flowState.selectedRefundOption?.id == option.id ? .white : .primary)
                        
                        if let bonus = option.bonusAmount, bonus > 0 {
                            Text("+$\(bonus, specifier: "%.2f") bonus")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Highlight for best value
                if option.bonusAmount != nil && option.bonusAmount! > 0 {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("Best Value")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(flowState.selectedRefundOption?.id == option.id ? .white : .green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(flowState.selectedRefundOption?.id == option.id ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(flowState.selectedRefundOption?.id == option.id ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func summarySection(_ decision: RefundDecision) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
            
            HStack {
                Text("Original Price")
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(decision.originalAmount, specifier: "%.2f")")
            }
            .font(.subheadline)
            
            if let fee = decision.restockingFee, fee > 0 {
                HStack {
                    Text("Restocking Fee")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("-$\(fee, specifier: "%.2f")")
                        .foregroundColor(.red)
                }
                .font(.subheadline)
            }
            
            Divider()
            
            if let selected = flowState.selectedRefundOption {
                HStack {
                    Text("Your Refund")
                        .fontWeight(.semibold)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("$\(selected.amount + (selected.bonusAmount ?? 0), specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text(optionTitle(selected.type))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helpers
    
    private func optionIcon(_ type: RefundOptionType) -> String {
        switch type {
        case .refundToOriginal: return "creditcard.fill"
        case .storeCredit: return "giftcard.fill"
        case .exchange: return "arrow.triangle.2.circlepath"
        case .partialRefund: return "minus.circle.fill"
        }
    }
    
    private func optionTitle(_ type: RefundOptionType) -> String {
        switch type {
        case .refundToOriginal: return "Refund to Card"
        case .storeCredit: return "Store Credit"
        case .exchange: return "Exchange Item"
        case .partialRefund: return "Partial Refund"
        }
    }
}
