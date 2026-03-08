import SwiftUI

/// Main ReturnClip Experience - orchestrates the entire return flow
struct ReturnClipExperience: View {
    @StateObject private var flowState = ReturnFlowState()
    @State private var showError = false
    
    // URL parameters from clip invocation
    let orderId: String
    
    init(orderId: String = "12345") {
        self.orderId = orderId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Color.rcSurface
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Step indicator
                    StepIndicator(currentStep: flowState.currentStep)
                    
                    // Current screen
                    currentScreen
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    // Bottom navigation
                    bottomNavigation
                }
                
                // Loading overlay
                if flowState.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle(flowState.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if flowState.currentStep != .orderConfirmation {
                        Button {
                            RCHaptics.impact(.light)
                            flowState.previousStep()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.rcPrimary)
                        }
                    }
                }
            }
            .toolbarBackground(Color.rcSurfaceElevated, for: .navigationBar)
        }
        .onAppear {
            loadOrderData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(flowState.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var currentScreen: some View {
        switch flowState.currentStep {
        case .orderConfirmation:
            OrderConfirmationView(flowState: flowState)
        case .returnReason:
            ReturnReasonView(flowState: flowState)
        case .photoCapture:
            PhotoCaptureView(flowState: flowState)
        case .conditionResult:
            ConditionResultView(flowState: flowState)
        case .refundOptions:
            RefundOptionsView(flowState: flowState)
        case .confirmation:
            ConfirmationView(flowState: flowState)
        }
    }
    
    private var bottomNavigation: some View {
        VStack(spacing: 0) {
            // Subtle top border
            Rectangle()
                .fill(Color.rcBorder.opacity(0.5))
                .frame(height: 1)
            
            HStack {
                if flowState.currentStep == .confirmation {
                    // Done button
                    Button {
                        RCHaptics.success()
                    } label: {
                        HStack(spacing: RCSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Done")
                        }
                    }
                    .buttonStyle(RCPrimaryButtonStyle())
                } else {
                    // Continue button
                    Button {
                        RCHaptics.impact(.medium)
                        handleContinue()
                    } label: {
                        HStack(spacing: RCSpacing.sm) {
                            Text(continueButtonText)
                            if flowState.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .buttonStyle(RCPrimaryButtonStyle(isEnabled: flowState.canProceed))
                    .disabled(!flowState.canProceed || flowState.isLoading)
                }
            }
            .padding(.horizontal, RCSpacing.lg)
            .padding(.top, RCSpacing.md)
            .padding(.bottom, RCSpacing.xl)
            .background(
                Color.rcSurfaceElevated
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -4)
            )
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: RCSpacing.lg) {
                // Animated pulse ring
                ZStack {
                    Circle()
                        .stroke(Color.rcPrimary.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.rcPrimary)
                }
                
                Text(loadingText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.rcTextPrimary)
                
                Text("This usually takes a few seconds")
                    .font(.caption)
                    .foregroundColor(.rcTextSecondary)
            }
            .padding(RCSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: RCRadius.xl)
                    .fill(.ultraThinMaterial)
            )
            .rcShadowElevated()
        }
    }
    
    // MARK: - Computed Properties
    
    private var continueButtonText: String {
        switch flowState.currentStep {
        case .orderConfirmation: return "Continue"
        case .returnReason: return "Continue"
        case .photoCapture: return "Analyze Photos"
        case .conditionResult: return "View Options"
        case .refundOptions:
            switch flowState.selectedRefundOption?.type {
            case .exchange: return "Place Exchange Order"
            case .storeCredit: return "Apply Store Credit"
            default: return "Confirm Return"
            }
        case .confirmation: return "Done"
        }
    }

    private var loadingText: String {
        switch flowState.currentStep {
        case .photoCapture: return "Uploading photos..."
        case .conditionResult: return "AI is analyzing condition..."
        case .refundOptions:
            switch flowState.selectedRefundOption?.type {
            case .exchange: return "Placing exchange order..."
            case .storeCredit: return "Saving store credit..."
            default: return "Processing return..."
            }
        default: return "Processing..."
        }
    }
    
    // MARK: - Actions
    
    private func loadOrderData() {
        Task {
            do {
                // Load the primary order
                let resp = try await BackendService.shared.lookupOrder(orderNumber: orderId)
                var loadedOrders = [resp.order]

                // Also load the other demo order so both items appear in the list
                let otherOrderId = orderId == "12345" ? "99999" : "12345"
                if let otherResp = try? await BackendService.shared.lookupOrder(orderNumber: otherOrderId) {
                    loadedOrders.append(otherResp.order)
                }

                // Merge all line items into the primary order for display
                let allItems = loadedOrders.flatMap { $0.lineItems }
                var mergedOrder = resp.order
                mergedOrder = Order(
                    id: resp.order.id,
                    orderNumber: resp.order.orderNumber,
                    purchaseDate: resp.order.purchaseDate,
                    purchaseLocation: resp.order.purchaseLocation,
                    customerEmail: resp.order.customerEmail,
                    customerName: resp.order.customerName,
                    lineItems: allItems,
                    totalPrice: resp.order.totalPrice,
                    currency: resp.order.currency,
                    paymentMethod: resp.order.paymentMethod
                )

                await MainActor.run {
                    flowState.orders = loadedOrders
                    flowState.order = mergedOrder
                    flowState.policy = resp.policy
                }
            } catch {
                await MainActor.run {
                    flowState.errorMessage = "Could not load order. Make sure the backend is running."
                    showError = true
                }
            }
        }
    }
    
    private func handleContinue() {
        switch flowState.currentStep {
        case .photoCapture:
            analyzePhotos()
        case .conditionResult:
            flowState.nextStep()
        case .refundOptions:
            confirmReturn()
        default:
            flowState.nextStep()
        }
    }
    
    private func analyzePhotos() {
        flowState.isLoading = true

        Task {
            do {
                guard let item = flowState.selectedItem,
                      let reason = flowState.returnReason else {
                    throw ReturnClipError.missingData
                }

                // Find the source order that contains the selected item
                let order = flowState.orders.first { o in
                    o.lineItems.contains { $0.id == item.id }
                } ?? flowState.order!


                // 1. Upload all photos to Cloudinary CDN
                var uploadedUrls: [String] = []
                for photoData in flowState.capturedPhotos {
                    let result = try await CloudinaryService.shared.uploadImage(
                        photoData,
                        orderId: order.id
                    )
                    uploadedUrls.append(result.secureUrl)
                }

                // 2. Create return case on backend
                let caseId = try await BackendService.shared.createCase(
                    orderId: order.id,
                    itemId: item.id,
                    reason: reason.rawValue,
                    notes: flowState.additionalNotes
                )

                // 3. Submit Cloudinary URLs as evidence
                if !uploadedUrls.isEmpty {
                    try await BackendService.shared.submitEvidence(caseId: caseId, imageUrls: uploadedUrls)
                }

                // 4. Run AI condition assessment (Gemini Vision on backend)
                let assessment = try await BackendService.shared.assessCondition(caseId: caseId)

                // 5. Get refund decision from backend
                let decision = try await BackendService.shared.getRefundDecision(caseId: caseId)

                await MainActor.run {
                    flowState.currentCaseId = caseId
                    flowState.conditionAssessment = assessment
                    flowState.refundDecision = decision
                    flowState.isLoading = false
                    flowState.nextStep()
                }

            } catch {
                await MainActor.run {
                    flowState.isLoading = false
                    flowState.errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func confirmReturn() {
        guard let option = flowState.selectedRefundOption else { return }
        flowState.isLoading = true

        Task {
            do {
                let caseId = flowState.currentCaseId ?? "demo_\(UUID().uuidString.prefix(8))"
                let exchProduct = flowState.selectedExchangeProduct
                let exchVariant = flowState.selectedExchangeVariant
                let resp = try await BackendService.shared.executeReturn(
                    caseId: caseId,
                    selectedOptionId: option.id,
                    exchangeProductTitle: option.type == .exchange ? exchProduct?.title : nil,
                    exchangeVariantTitle: option.type == .exchange ? exchVariant?.title : nil,
                    exchangePrice: option.type == .exchange ? exchVariant?.price : nil
                )

                await MainActor.run {
                    RCHaptics.success()
                    let totalAmount = option.amount + (option.bonusAmount ?? 0)
                    switch option.type {
                    case .exchange:
                        let product = flowState.selectedExchangeProduct
                        let variant = flowState.selectedExchangeVariant
                        let returnAmt = NSDecimalNumber(decimal: option.amount).doubleValue
                        let exchPrice = variant?.price ?? returnAmt
                        let diff = abs(returnAmt - exchPrice)
                        flowState.confirmationResult = .exchange(
                            productTitle: product?.title ?? "Exchange Item",
                            variantTitle: variant?.title ?? "Standard",
                            exchangePrice: exchPrice,
                            returnAmount: returnAmt,
                            difference: diff,
                            differenceType: returnAmt >= exchPrice ? "refund" : "charge",
                            exchangeOrderId: resp.executionId,
                            estimatedDelivery: "3–5 business days"
                        )
                    case .storeCredit:
                        flowState.confirmationResult = .storeCredit(
                            amount: totalAmount,
                            creditId: resp.executionId
                        )
                    default:
                        let refundAmt = resp.refundAmount.map { Decimal($0) } ?? totalAmount
                        flowState.confirmationResult = .refund(amount: refundAmt)
                    }
                    flowState.isLoading = false
                    flowState.nextStep()
                }
            } catch {
                // Fallback — build a mock result so the demo always proceeds
                await MainActor.run {
                    RCHaptics.success()
                    let totalAmount = option.amount + (option.bonusAmount ?? 0)
                    switch option.type {
                    case .exchange:
                        let product = flowState.selectedExchangeProduct
                        let variant = flowState.selectedExchangeVariant
                        let returnAmt = NSDecimalNumber(decimal: option.amount).doubleValue
                        let exchPrice = variant?.price ?? returnAmt
                        let diff = abs(returnAmt - exchPrice)
                        flowState.confirmationResult = .exchange(
                            productTitle: product?.title ?? "Exchange Item",
                            variantTitle: variant?.title ?? "Standard",
                            exchangePrice: exchPrice,
                            returnAmount: returnAmt,
                            difference: diff,
                            differenceType: returnAmt >= exchPrice ? "refund" : "charge",
                            exchangeOrderId: "EX-\(Int.random(in: 10000...99999))",
                            estimatedDelivery: "3–5 business days"
                        )
                    case .storeCredit:
                        flowState.confirmationResult = .storeCredit(
                            amount: totalAmount,
                            creditId: "SC-\(Int.random(in: 10000...99999))"
                        )
                    default:
                        flowState.confirmationResult = .refund(amount: totalAmount)
                    }
                    flowState.isLoading = false
                    flowState.nextStep()
                }
            }
        }
    }
}

// MARK: - Errors

enum ReturnClipError: Error, LocalizedError {
    case missingData
    case uploadFailed
    case analysisFailed
    
    var errorDescription: String? {
        switch self {
        case .missingData: return "Missing required data"
        case .uploadFailed: return "Failed to upload photos"
        case .analysisFailed: return "Failed to analyze condition"
        }
    }
}

// MARK: - Preview

struct ReturnClipExperience_Previews: PreviewProvider {
    static var previews: some View {
        ReturnClipExperience(orderId: "12345")
    }
}
