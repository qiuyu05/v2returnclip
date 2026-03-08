import SwiftUI

/// Exchange product browser — shown when user selects "Exchange Item"
struct ExchangeProductsView: View {
    @ObservedObject var flowState: ReturnFlowState
    @Environment(\.dismiss) private var dismiss

    @State private var products: [ShopifyProduct] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedProduct: ShopifyProduct?
    @State private var selectedVariant: ShopifyVariant?

    // Price cap: exchange item must be <= the returned item's value
    private var returnItemPrice: Double {
        NSDecimalNumber(decimal: flowState.selectedItem?.price ?? 0).doubleValue
    }

    private var eligibleProducts: [ShopifyProduct] {
        products.filter { product in
            product.variants.contains { $0.availableForSale && $0.price <= returnItemPrice }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if let error {
                    errorView(error)
                } else {
                    productList
                }
            }
            .navigationTitle("Choose Exchange Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.rcPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        if let product = selectedProduct, let variant = selectedVariant {
                            flowState.selectedExchangeProduct = product
                            flowState.selectedExchangeVariant = variant
                            dismiss()
                        }
                    }
                    .foregroundColor(.rcPrimary)
                    .fontWeight(.semibold)
                    .disabled(selectedVariant == nil)
                }
            }
        }
        .task { await loadProducts() }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: RCSpacing.lg) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.rcPrimary)
            Text("Loading products...")
                .font(.subheadline)
                .foregroundColor(.rcTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rcSurface)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: RCSpacing.lg) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(.rcTextMuted)
            Text("Could not load products")
                .font(.headline)
                .foregroundColor(.rcTextPrimary)
            Text(message)
                .font(.caption)
                .foregroundColor(.rcTextSecondary)
                .multilineTextAlignment(.center)
            Button("Try Again") { Task { await loadProducts() } }
                .buttonStyle(RCPrimaryButtonStyle())
        }
        .padding(RCSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rcSurface)
    }

    private var productList: some View {
        Group {
            if eligibleProducts.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: RCSpacing.md) {
                        if let selected = selectedProduct {
                            variantPicker(for: selected)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        ForEach(eligibleProducts) { product in
                            ProductCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        RCHaptics.selection()
                                        if selectedProduct?.id == product.id {
                                            selectedProduct = nil
                                            selectedVariant = nil
                                        } else {
                                            selectedProduct = product
                                            selectedVariant = product.variants.first(where: { $0.availableForSale && $0.price <= returnItemPrice })
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, RCSpacing.lg)
                    .padding(.top, RCSpacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color.rcSurface)
    }

    private var emptyStateView: some View {
        VStack(spacing: RCSpacing.lg) {
            Image(systemName: "tag.slash")
                .font(.system(size: 40))
                .foregroundColor(.rcTextMuted)
            Text("No exchange items available")
                .font(.headline)
                .foregroundColor(.rcTextPrimary)
            Text("There are no products priced at or below your return item value.")
                .font(.caption)
                .foregroundColor(.rcTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(RCSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func variantPicker(for product: ShopifyProduct) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.sm) {
            Text("Select variant for \(product.title)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.rcTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RCSpacing.sm) {
                    ForEach(product.variants.filter { $0.availableForSale && $0.price <= returnItemPrice }) { variant in
                        let isSelected = selectedVariant?.id == variant.id
                        Button {
                            RCHaptics.selection()
                            selectedVariant = variant
                        } label: {
                            Text(variant.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isSelected ? .white : .rcTextPrimary)
                                .padding(.horizontal, RCSpacing.md)
                                .padding(.vertical, RCSpacing.sm)
                                .background(isSelected ? Color.rcPrimary : Color.rcSurfaceElevated)
                                .cornerRadius(RCRadius.full)
                                .overlay(
                                    RoundedRectangle(cornerRadius: RCRadius.full)
                                        .stroke(isSelected ? Color.clear : Color.rcBorder, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .rcCard()
    }

    // MARK: - Data Loading

    private func loadProducts() async {
        isLoading = true
        error = nil
        do {
            products = try await BackendService.shared.fetchProducts()
        } catch {
            self.error = error.localizedDescription
            products = []
        }
        isLoading = false
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: ShopifyProduct
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RCSpacing.lg) {
                // Product image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        ZStack {
                            Color.rcSurfaceMuted
                            Image(systemName: "photo")
                                .foregroundColor(.rcTextMuted)
                                .font(.system(size: 20))
                        }
                    @unknown default:
                        Color.rcSurfaceMuted
                    }
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(RCRadius.md)

                // Product info
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.rcTextPrimary)
                        .lineLimit(2)

                    Text(product.formattedPrice)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.rcPrimary)

                    Text("\(product.variants.filter(\.availableForSale).count) variants available")
                        .font(.system(size: 12))
                        .foregroundColor(.rcTextMuted)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.rcPrimary : Color.rcBorder.opacity(0.4))
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(RCSpacing.lg)
            .background(isSelected ? Color.rcPrimary.opacity(0.05) : Color.rcSurfaceElevated)
            .cornerRadius(RCRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: RCRadius.lg)
                    .stroke(isSelected ? Color.rcPrimary.opacity(0.5) : Color.rcBorder.opacity(0.6), lineWidth: isSelected ? 2 : 1)
            )
            .rcShadowCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
