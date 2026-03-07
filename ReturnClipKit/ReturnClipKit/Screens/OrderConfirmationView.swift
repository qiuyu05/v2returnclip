import SwiftUI

/// Screen 1: Confirm order details and select item to return
struct OrderConfirmationView: View {
    @ObservedObject var flowState: ReturnFlowState
    
    var body: some View {
        ScrollView {
            VStack(spacing: RCSpacing.xl) {
                // Header
                headerSection
                    .slideIn(delay: 0.1)
                
                // Order Info
                if let order = flowState.order {
                    orderInfoCard(order)
                        .slideIn(delay: 0.2)
                    
                    // Items to return
                    itemSelectionSection(order)
                        .slideIn(delay: 0.3)
                    
                    // Return window status
                    if let policy = flowState.policy {
                        returnWindowCard(order: order, policy: policy)
                            .slideIn(delay: 0.4)
                    }
                } else {
                    loadingView
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
                    .fill(Color.rcPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.rcPrimary)
            }
            .bounceAppear(delay: 0.1)
            
            Text("Start Your Return")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            Text("Confirm your order details below")
                .font(.subheadline)
                .foregroundColor(.rcTextSecondary)
        }
        .padding(.top, RCSpacing.lg)
    }
    
    private func orderInfoCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.orderNumber)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.rcTextPrimary)
                    Text(order.formattedDate)
                        .font(.caption)
                        .foregroundColor(.rcTextSecondary)
                }
                Spacer()
                // Currency badge
                Text(order.currency)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.rcPrimary)
                    .padding(.horizontal, RCSpacing.sm)
                    .padding(.vertical, RCSpacing.xs)
                    .background(Color.rcPrimary.opacity(0.1))
                    .cornerRadius(RCRadius.full)
            }
            
            Divider()
                .background(Color.rcBorder)
            
            HStack(spacing: RCSpacing.lg) {
                HStack(spacing: RCSpacing.sm) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.rcPrimary)
                    Text(order.purchaseLocation)
                        .font(.subheadline)
                        .foregroundColor(.rcTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: RCSpacing.sm) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.rcPrimary)
                    Text(order.paymentMethod.displayName)
                        .font(.subheadline)
                        .foregroundColor(.rcTextSecondary)
                }
            }
        }
        .rcCard()
    }
    
    private func itemSelectionSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.md) {
            Text("Select item to return")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            ForEach(order.lineItems) { item in
                itemCard(item)
            }
        }
    }
    
    private func itemCard(_ item: LineItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                RCHaptics.selection()
                flowState.selectedItem = item
            }
        } label: {
            HStack(spacing: RCSpacing.lg) {
                // Product image
                AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.rcSurfaceMuted
                        Image(systemName: "photo")
                            .foregroundColor(.rcTextMuted)
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(RCRadius.md)
                
                VStack(alignment: .leading, spacing: RCSpacing.xs) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.rcTextPrimary)
                        .lineLimit(2)
                    
                    if let variant = item.variantTitle {
                        Text(variant)
                            .font(.caption)
                            .foregroundColor(.rcTextSecondary)
                    }
                    
                    Text("$\(item.price.currencyString)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.rcPrimary)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(flowState.selectedItem?.id == item.id ? Color.rcPrimary : Color.rcBorder, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if flowState.selectedItem?.id == item.id {
                        Circle()
                            .fill(Color.rcPrimary)
                            .frame(width: 16, height: 16)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .rcCard(isSelected: flowState.selectedItem?.id == item.id)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func returnWindowCard(order: Order, policy: ReturnPolicy) -> some View {
        let daysRemaining = policy.daysRemaining(daysSincePurchase: order.daysSincePurchase)
        let isWithinWindow = policy.isWithinReturnWindow(daysSincePurchase: order.daysSincePurchase)
        
        return HStack(spacing: RCSpacing.md) {
            ZStack {
                Circle()
                    .fill(isWithinWindow ? Color.rcSuccess.opacity(0.15) : Color.rcError.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isWithinWindow ? "clock.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isWithinWindow ? .rcSuccess : .rcError)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isWithinWindow ? "Return window open" : "Return window closed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isWithinWindow ? .rcSuccessDark : .rcError)
                
                Text(isWithinWindow ? "\(daysRemaining) days remaining" : "Outside \(policy.returnWindowDays)-day policy")
                    .font(.caption)
                    .foregroundColor(.rcTextSecondary)
            }
            
            Spacer()
            
            if isWithinWindow {
                Text("\(daysRemaining)d")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.rcSuccess)
            }
        }
        .padding(RCSpacing.lg)
        .background(isWithinWindow ? Color.rcSuccess.opacity(0.06) : Color.rcError.opacity(0.06))
        .cornerRadius(RCRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: RCRadius.lg)
                .stroke(isWithinWindow ? Color.rcSuccess.opacity(0.2) : Color.rcError.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: RCSpacing.lg) {
            ProgressView()
                .tint(.rcPrimary)
            Text("Loading order...")
                .font(.subheadline)
                .foregroundColor(.rcTextSecondary)
        }
        .padding(40)
    }
}
