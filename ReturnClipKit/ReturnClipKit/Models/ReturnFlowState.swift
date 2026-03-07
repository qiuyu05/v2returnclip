import Foundation
import SwiftUI

/// Tracks the state of the return flow
class ReturnFlowState: ObservableObject {
    // Navigation
    @Published var currentStep: ReturnStep = .orderConfirmation
    
    // Order data
    @Published var order: Order?
    @Published var policy: ReturnPolicy?
    @Published var selectedItem: LineItem?
    
    // Return details
    @Published var returnReason: ReturnReason?
    @Published var additionalNotes: String = ""
    
    // Photos/Video
    @Published var capturedPhotos: [Data] = []
    @Published var capturedVideo: Data?
    
    // AI Analysis
    @Published var conditionAssessment: ConditionAssessment?
    @Published var refundDecision: RefundDecision?
    
    // Selection
    @Published var selectedRefundOption: RefundOption?
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Computed
    var canProceed: Bool {
        switch currentStep {
        case .orderConfirmation:
            return order != nil && selectedItem != nil
        case .returnReason:
            return returnReason != nil
        case .photoCapture:
            return !capturedPhotos.isEmpty || capturedVideo != nil
        case .conditionResult:
            return conditionAssessment != nil
        case .refundOptions:
            return selectedRefundOption != nil
        case .confirmation:
            return true
        }
    }
    
    func nextStep() {
        guard let next = currentStep.next else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = next
        }
    }
    
    func previousStep() {
        guard let prev = currentStep.previous else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prev
        }
    }
    
    func reset() {
        currentStep = .orderConfirmation
        selectedItem = nil
        returnReason = nil
        additionalNotes = ""
        capturedPhotos = []
        capturedVideo = nil
        conditionAssessment = nil
        refundDecision = nil
        selectedRefundOption = nil
        isLoading = false
        errorMessage = nil
    }
}

enum ReturnStep: Int, CaseIterable {
    case orderConfirmation = 0
    case returnReason = 1
    case photoCapture = 2
    case conditionResult = 3
    case refundOptions = 4
    case confirmation = 5
    
    var title: String {
        switch self {
        case .orderConfirmation: return "Confirm Order"
        case .returnReason: return "Return Reason"
        case .photoCapture: return "Photo Verification"
        case .conditionResult: return "Condition Assessment"
        case .refundOptions: return "Refund Options"
        case .confirmation: return "Confirmation"
        }
    }
    
    var next: ReturnStep? {
        ReturnStep(rawValue: rawValue + 1)
    }
    
    var previous: ReturnStep? {
        ReturnStep(rawValue: rawValue - 1)
    }
    
    var progress: Double {
        Double(rawValue + 1) / Double(ReturnStep.allCases.count)
    }
}

enum ReturnReason: String, CaseIterable, Identifiable {
    case changedMind = "changed_mind"
    case doesntFit = "doesnt_fit"
    case notAsDescribed = "not_as_described"
    case damagedOnArrival = "damaged_on_arrival"
    case wrongItem = "wrong_item"
    case defective = "defective"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .changedMind: return "Changed my mind"
        case .doesntFit: return "Doesn't fit / wrong size"
        case .notAsDescribed: return "Not as described"
        case .damagedOnArrival: return "Damaged on arrival"
        case .wrongItem: return "Received wrong item"
        case .defective: return "Product is defective"
        case .other: return "Other reason"
        }
    }
    
    var icon: String {
        switch self {
        case .changedMind: return "arrow.uturn.backward"
        case .doesntFit: return "ruler"
        case .notAsDescribed: return "exclamationmark.circle"
        case .damagedOnArrival: return "shippingbox.and.arrow.backward"
        case .wrongItem: return "questionmark.circle"
        case .defective: return "xmark.circle"
        case .other: return "ellipsis.circle"
        }
    }
    
    var requiresPhotos: Bool {
        switch self {
        case .damagedOnArrival, .defective, .notAsDescribed:
            return true
        default:
            return false
        }
    }
}
