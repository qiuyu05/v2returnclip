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
        case .refundOptions: return "Confirm Return"
        case .confirmation: return "Done"
        }
    }
    
    private var loadingText: String {
        switch flowState.currentStep {
        case .photoCapture: return "Uploading photos..."
        case .conditionResult: return "AI is analyzing condition..."
        default: return "Processing..."
        }
    }
    
    // MARK: - Actions
    
    private func loadOrderData() {
        // Load order from mock data (in production, fetch from Shopify)
        flowState.order = MockData.getOrder(for: orderId)
        flowState.policy = MockData.getPolicy(for: "refined_concept")
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
                // 1. Upload photos to Cloudinary
                var uploadedUrls: [String] = []
                for photoData in flowState.capturedPhotos {
                    let result = try await CloudinaryService.shared.uploadImage(photoData)
                    uploadedUrls.append(result.secureUrl)
                }
                
                // 2. Analyze condition with Cloudinary Vision
                let cloudinaryAnalysis = try await CloudinaryService.shared.analyzeCondition(imageUrls: uploadedUrls)
                
                // 3. Get refund decision from Gemini
                guard let order = flowState.order,
                      let item = flowState.selectedItem,
                      let reason = flowState.returnReason,
                      let policy = flowState.policy else {
                    throw ReturnClipError.missingData
                }
                
                let decision = try await GeminiService.shared.analyzeReturnEligibility(
                    order: order,
                    item: item,
                    reason: reason,
                    policy: policy,
                    cloudinaryAnalysis: cloudinaryAnalysis
                )
                
                // 4. Update state
                await MainActor.run {
                    flowState.conditionAssessment = MockData.excellentConditionAssessment
                    flowState.refundDecision = decision
                    flowState.isLoading = false
                    flowState.nextStep()
                }
                
            } catch {
                await MainActor.run {
                    // Use mock data for demo if API fails
                    flowState.conditionAssessment = MockData.excellentConditionAssessment
                    flowState.refundDecision = MockData.fullRefundDecision
                    flowState.isLoading = false
                    flowState.nextStep()
                }
            }
        }
    }
    
    private func confirmReturn() {
        flowState.isLoading = true
        
        // Simulate API call to create return
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            RCHaptics.success()
            flowState.isLoading = false
            flowState.nextStep()
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
