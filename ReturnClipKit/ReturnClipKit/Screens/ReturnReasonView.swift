import SwiftUI

/// Screen 2: Select reason for return
struct ReturnReasonView: View {
    @ObservedObject var flowState: ReturnFlowState
    @State private var showNotesField = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: RCSpacing.xl) {
                // Header
                headerSection
                    .slideIn(delay: 0.1)
                
                // Reason options
                reasonGrid
                    .slideIn(delay: 0.2)
                
                // Additional notes
                if showNotesField || flowState.returnReason == .other {
                    notesSection
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
            if let item = flowState.selectedItem {
                HStack(spacing: RCSpacing.sm) {
                    Image(systemName: "cube.box.fill")
                        .font(.caption)
                        .foregroundColor(.rcPrimary)
                    Text("Returning: \(item.title)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.rcTextSecondary)
                }
                .padding(.horizontal, RCSpacing.md)
                .padding(.vertical, RCSpacing.sm)
                .background(Color.rcPrimary.opacity(0.08))
                .cornerRadius(RCRadius.full)
            }
            
            Text("Why are you returning?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            Text("This helps us improve our products")
                .font(.subheadline)
                .foregroundColor(.rcTextSecondary)
        }
        .padding(.top, RCSpacing.lg)
    }
    
    private var reasonGrid: some View {
        VStack(spacing: RCSpacing.md) {
            ForEach(Array(ReturnReason.allCases.enumerated()), id: \.element) { index, reason in
                reasonButton(reason)
                    .slideIn(delay: 0.15 + Double(index) * 0.05)
            }
        }
    }
    
    private func reasonButton(_ reason: ReturnReason) -> some View {
        let isSelected = flowState.returnReason == reason
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                RCHaptics.selection()
                flowState.returnReason = reason
                if reason == .other {
                    showNotesField = true
                }
            }
        } label: {
            HStack(spacing: RCSpacing.lg) {
                // Icon with tinted background
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.rcPrimary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: reason.icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .white : .rcPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? .white : .rcTextPrimary)
                    
                    if reason.requiresPhotos {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 9))
                            Text("Photo required")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .rcTextMuted)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.white.opacity(0.5) : Color.rcBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
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
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: RCSpacing.sm) {
            Text("Additional details (optional)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.rcTextPrimary)
            
            TextEditor(text: $flowState.additionalNotes)
                .frame(height: 100)
                .padding(RCSpacing.md)
                .background(Color.rcSurfaceElevated)
                .cornerRadius(RCRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: RCRadius.md)
                        .stroke(Color.rcBorder, lineWidth: 1)
                )
        }
        .slideIn(delay: 0.1)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
