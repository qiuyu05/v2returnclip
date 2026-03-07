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
                // Main content
                VStack(spacing: 0) {
                    // Progress bar
                    progressBar
                    
                    // Current screen
                    currentScreen
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
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
                            flowState.previousStep()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
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
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geo.size.width * flowState.currentStep.progress)
                    .animation(.easeInOut(duration: 0.3), value: flowState.currentStep)
            }
        }
        .frame(height: 4)
    }
    
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
            Divider()
            
            HStack {
                if flowState.currentStep == .confirmation {
                    // Done button
                    Button {
                        // Close clip or return to app
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                } else {
                    // Continue button
                    Button {
                        handleContinue()
                    } label: {
                        HStack {
                            Text(continueButtonText)
                                .fontWeight(.semibold)
                            if flowState.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(flowState.canProceed ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!flowState.canProceed || flowState.isLoading)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(loadingText)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(32)
            .background(Color(.systemGray5).opacity(0.9))
            .cornerRadius(16)
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
        case .conditionResult: return "Analyzing condition..."
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
                    flowState.conditionAssessment = MockData.excellentConditionAssessment  // Use mock for demo
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
