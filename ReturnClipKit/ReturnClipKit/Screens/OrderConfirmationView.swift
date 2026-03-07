import SwiftUI

/// Screen 1: Confirm order details and select item to return
struct OrderConfirmationView: View {
    @ObservedObject var flowState: ReturnFlowState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Order Info
                if let order = flowState.order {
                    orderInfoCard(order)
                    
                    // Items to return
                    itemSelectionSection(order)
                    
                    // Return window status
                    if let policy = flowState.policy {
                        returnWindowCard(order: order, policy: policy)
                    }
                } else {
                    loadingView
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "shippingbox.and.arrow.backward.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Start Your Return")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Confirm your order details")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    private func orderInfoCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.orderNumber)
                    .font(.headline)
                Spacer()
                Text(order.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.blue)
                Text(order.purchaseLocation)
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                Text(order.paymentMethod.displayName)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func itemSelectionSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select item to return")
                .font(.headline)
            
            ForEach(order.lineItems) { item in
                itemCard(item)
            }
        }
    }
    
    private func itemCard(_ item: LineItem) -> some View {
        Button {
            withAnimation {
                flowState.selectedItem = item
            }
        } label: {
            HStack(spacing: 16) {
                // Product image placeholder
                AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let variant = item.variantTitle {
                        Text(variant)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: flowState.selectedItem?.id == item.id ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(flowState.selectedItem?.id == item.id ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(flowState.selectedItem?.id == item.id ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func returnWindowCard(order: Order, policy: ReturnPolicy) -> some View {
        let daysRemaining = policy.daysRemaining(daysSincePurchase: order.daysSincePurchase)
        let isWithinWindow = policy.isWithinReturnWindow(daysSincePurchase: order.daysSincePurchase)
        
        return HStack {
            Image(systemName: isWithinWindow ? "clock.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isWithinWindow ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(isWithinWindow ? "Return window open" : "Return window closed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(isWithinWindow ? "\(daysRemaining) days remaining" : "Outside \(policy.returnWindowDays)-day policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(isWithinWindow ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading order...")
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}
