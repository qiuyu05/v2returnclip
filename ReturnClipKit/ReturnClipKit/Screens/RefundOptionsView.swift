import SwiftUI

/// Screen 5: Choose refund option
struct RefundOptionsView: View {
    @ObservedObject var flowState: ReturnFlowState
    
    var body: some View {
        ScrollView {
            VStack(spacing: RCSpacing.xl) {
                // Header
                headerSection
                    .slideIn(delay: 0.1)
                
                // Refund options
                if let decision = flowState.refundDecision {
                    optionsSection(decision)
                    
                    // Summary
                    summarySection(decision)
                        .slideIn(delay: 0.4)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, RCSpacing.lg)
            .padding(.top, RCSpacing.sm)
        }
        .background(Color.rcSurface)
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: RCSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.rcSuccess.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.rcSuccess)
            }
            .bounceAppear(delay: 0.1)
            
            Text("Choose Your Refund")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            Text("Select the option that works best for you")
                .font(.subheadline)
                .foregroundColor(.rcTextSecondary)
        }
        .padding(.top, RCSpacing.lg)
    }
    
    private func optionsSection(_ decision: RefundDecision) -> some View {
        VStack(spacing: RCSpacing.md) {
            ForEach(Array(decision.alternativeOptions.enumerated()), id: \.element.id) { index, option in
                optionCard(option)
                    .slideIn(delay: 0.2 + Double(index) * 0.1)
            }
        }
    }
    
    private func optionCard(_ option: RefundOption) -> some View {
        let isSelected = flowState.selectedRefundOption?.id == option.id
        let hasBestValue = option.bonusAmount != nil && option.bonusAmount! > 0
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                RCHaptics.selection()
                flowState.selectedRefundOption = option
            }
        } label: {
            VStack(alignment: .leading, spacing: RCSpacing.md) {
                HStack(spacing: RCSpacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.rcPrimary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: optionIcon(option.type))
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? .white : .rcPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(optionTitle(option.type))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .rcTextPrimary)
                        
                        Text(option.description)
                            .font(.system(size: 12))
                            .foregroundColor(isSelected ? .white.opacity(0.7) : .rcTextSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Amount
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("$\(option.amount.currencyString)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .rcTextPrimary)
                        
                        if let bonus = option.bonusAmount, bonus > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 9))
                                Text("$\(bonus.currencyString)")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(isSelected ? .white : .rcSuccess)
                            .padding(.horizontal, RCSpacing.sm)
                            .padding(.vertical, 3)
                            .background(
                                isSelected
                                ? Color.white.opacity(0.2)
                                : Color.rcSuccess.opacity(0.1)
                            )
                            .cornerRadius(RCRadius.full)
                        }
                    }
                }
                
                // Best value badge
                if hasBestValue {
                    HStack(spacing: RCSpacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("Best Value — Extra \(Int((option.bonusAmount ?? 0).doubleValue / option.amount.doubleValue * 100))% bonus")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isSelected ? .white : .rcSuccess)
                    .padding(.horizontal, RCSpacing.md)
                    .padding(.vertical, RCSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isSelected
                        ? Color.white.opacity(0.15)
                        : Color.rcSuccess.opacity(0.06)
                    )
                    .cornerRadius(RCRadius.sm)
                }
            }
            .padding(RCSpacing.lg)
            .background(
                Group {
                    if isSelected {
                        LinearGradient.rcPrimary
                    } else {
                        LinearGradient(colors: [Color.rcSurfaceElevated], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .cornerRadius(RCRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: RCRadius.lg)
                    .stroke(isSelected ? Color.clear : Color.rcBorder.opacity(0.6), lineWidth: 1)
            )
            .rcShadowCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func summarySection(_ decision: RefundDecision) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.md) {
            Text("Summary")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            HStack {
                Text("Original Price")
                    .font(.system(size: 14))
                    .foregroundColor(.rcTextSecondary)
                Spacer()
                Text("$\(decision.originalAmount.currencyString)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.rcTextPrimary)
            }
            
            if let fee = decision.restockingFee, fee > 0 {
                HStack {
                    Text("Restocking Fee")
                        .font(.system(size: 14))
                        .foregroundColor(.rcTextSecondary)
                    Spacer()
                    Text("-$\(fee.currencyString)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.rcError)
                }
            }
            
            Rectangle()
                .fill(Color.rcBorder)
                .frame(height: 1)
            
            if let selected = flowState.selectedRefundOption {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Refund")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.rcTextPrimary)
                        Text(optionTitle(selected.type))
                            .font(.system(size: 12))
                            .foregroundColor(.rcTextMuted)
                    }
                    Spacer()
                    Text("$\((selected.amount + (selected.bonusAmount ?? 0)).currencyString)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.rcSuccess)
                }
            }
        }
        .rcCard()
    }
    
    // MARK: - Helpers
    
    private func optionIcon(_ type: RefundOptionType) -> String {
        switch type {
        case .refundToOriginal: return "creditcard.fill"
        case .storeCredit: return "gift.fill"
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
