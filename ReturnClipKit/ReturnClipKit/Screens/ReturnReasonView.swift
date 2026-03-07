import SwiftUI

/// Screen 2: Select reason for return
struct ReturnReasonView: View {
    @ObservedObject var flowState: ReturnFlowState
    @State private var showNotesField = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Reason options
                reasonGrid
                
                // Additional notes
                if showNotesField || flowState.returnReason == .other {
                    notesSection
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            if let item = flowState.selectedItem {
                Text("Returning: \(item.title)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text("Why are you returning?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This helps us improve")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    private var reasonGrid: some View {
        VStack(spacing: 12) {
            ForEach(ReturnReason.allCases) { reason in
                reasonButton(reason)
            }
        }
    }
    
    private func reasonButton(_ reason: ReturnReason) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                flowState.returnReason = reason
                if reason == .other {
                    showNotesField = true
                }
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: reason.icon)
                    .font(.title2)
                    .frame(width: 40)
                    .foregroundColor(flowState.returnReason == reason ? .white : .blue)
                
                Text(reason.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(flowState.returnReason == reason ? .white : .primary)
                
                Spacer()
                
                if reason.requiresPhotos {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(flowState.returnReason == reason ? .white.opacity(0.8) : .secondary)
                }
                
                Image(systemName: flowState.returnReason == reason ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(flowState.returnReason == reason ? .white : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(flowState.returnReason == reason ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional details (optional)")
                .font(.headline)
            
            TextEditor(text: $flowState.additionalNotes)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
