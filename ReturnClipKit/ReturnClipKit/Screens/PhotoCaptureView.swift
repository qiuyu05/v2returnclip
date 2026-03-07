import SwiftUI
import PhotosUI

/// Screen 3: Capture photos/video of item condition
struct PhotoCaptureView: View {
    @ObservedObject var flowState: ReturnFlowState
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showDemoVideo = false
    
    private let requiredPhotoCount = 3
    
    var body: some View {
        ScrollView {
            VStack(spacing: RCSpacing.xl) {
                // Header
                headerSection
                    .slideIn(delay: 0.1)
                
                // Demo video button
                if flowState.policy?.demoVideoUrl != nil {
                    demoVideoButton
                        .slideIn(delay: 0.15)
                }
                
                // Photo guidelines
                guidelinesSection
                    .slideIn(delay: 0.2)
                
                // Photo capture area
                photoCaptureSection
                    .slideIn(delay: 0.25)
                
                // Photo preview grid
                if !flowState.capturedPhotos.isEmpty {
                    photoPreviewGrid
                        .slideIn(delay: 0.1)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, RCSpacing.lg)
            .padding(.top, RCSpacing.sm)
        }
        .background(Color.rcSurface)
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhotos,
            maxSelectionCount: requiredPhotoCount - flowState.capturedPhotos.count,
            matching: .images
        )
        .onChange(of: selectedPhotos) { newItems in
            Task {
                await loadSelectedPhotos(newItems)
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: RCSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.rcPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.rcPrimary)
            }
            .bounceAppear(delay: 0.1)
            
            Text("Photo Verification")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            Text("Take \(requiredPhotoCount) photos of your item")
                .font(.subheadline)
                .foregroundColor(.rcTextSecondary)
            
            // Progress dots
            HStack(spacing: RCSpacing.md) {
                ForEach(0..<requiredPhotoCount, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(index < flowState.capturedPhotos.count ? Color.rcPrimary : Color.rcBorder.opacity(0.5))
                            .frame(width: 12, height: 12)
                        
                        if index < flowState.capturedPhotos.count {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(index < flowState.capturedPhotos.count ? 1.0 : 0.85)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: flowState.capturedPhotos.count)
                }
            }
            .padding(.top, RCSpacing.xs)
        }
        .padding(.top, RCSpacing.lg)
    }
    
    private var demoVideoButton: some View {
        Button {
            showDemoVideo = true
        } label: {
            HStack(spacing: RCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.rcPrimary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.rcPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("How to photograph your item")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.rcTextPrimary)
                    Text("Watch a 15-second guide")
                        .font(.caption)
                        .foregroundColor(.rcTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.rcTextMuted)
            }
            .padding(RCSpacing.lg)
            .background(Color.rcSurfaceElevated)
            .cornerRadius(RCRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: RCRadius.lg)
                    .stroke(Color.rcBorder.opacity(0.6), lineWidth: 1)
            )
            .rcShadowCard()
        }
        .sheet(isPresented: $showDemoVideo) {
            DemoVideoView()
        }
    }
    
    private var guidelinesSection: some View {
        VStack(alignment: .leading, spacing: RCSpacing.md) {
            Text("Photo Guidelines")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            GuidelineRow(icon: "1.circle.fill", text: "Front view — entire item visible", color: .rcPrimary)
            GuidelineRow(icon: "2.circle.fill", text: "Back/underside — show all angles", color: .rcPrimary)
            GuidelineRow(icon: "3.circle.fill", text: "Close-up of any damage or wear", color: .rcPrimary)
            
            HStack(spacing: RCSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.rcWarning)
                    .font(.caption)
                Text("Good lighting helps our AI assess faster")
                    .font(.system(size: 12))
                    .foregroundColor(.rcTextSecondary)
            }
            .padding(.top, RCSpacing.xs)
        }
        .rcCard()
    }
    
    private var photoCaptureSection: some View {
        VStack(spacing: RCSpacing.md) {
            // Camera button
            Button {
                RCHaptics.impact(.medium)
                showingCamera = true
            } label: {
                HStack(spacing: RCSpacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                    Text("Take Photo")
                }
            }
            .buttonStyle(RCPrimaryButtonStyle())
            
            // Photo library button
            Button {
                RCHaptics.selection()
                showingImagePicker = true
            } label: {
                HStack(spacing: RCSpacing.sm) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                    Text("Choose from Library")
                }
            }
            .buttonStyle(RCSecondaryButtonStyle())
        }
    }
    
    private var photoPreviewGrid: some View {
        VStack(alignment: .leading, spacing: RCSpacing.md) {
            HStack {
                Text("Your Photos")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.rcTextPrimary)
                Spacer()
                Text("\(flowState.capturedPhotos.count)/\(requiredPhotoCount)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.rcPrimary)
                    .padding(.horizontal, RCSpacing.sm)
                    .padding(.vertical, RCSpacing.xs)
                    .background(Color.rcPrimary.opacity(0.1))
                    .cornerRadius(RCRadius.full)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: RCSpacing.md) {
                ForEach(flowState.capturedPhotos.indices, id: \.self) { index in
                    PhotoPreviewCell(
                        imageData: flowState.capturedPhotos[index],
                        onDelete: {
                            withAnimation(.spring(response: 0.3)) {
                                RCHaptics.impact(.light)
                                flowState.capturedPhotos.remove(at: index)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    flowState.capturedPhotos.append(data)
                }
            }
        }
        selectedPhotos = []
    }
}

// MARK: - Supporting Views

struct GuidelineRow: View {
    let icon: String
    let text: String
    var color: Color = .rcPrimary
    
    var body: some View {
        HStack(spacing: RCSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.rcTextSecondary)
        }
    }
}

struct PhotoPreviewCell: View {
    let imageData: Data
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()
                    .cornerRadius(RCRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: RCRadius.md)
                            .stroke(Color.rcBorder, lineWidth: 1)
                    )
            }
            
            Button(action: onDelete) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(6)
        }
    }
}

struct DemoVideoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Placeholder for video player
                ZStack {
                    RoundedRectangle(cornerRadius: RCRadius.lg)
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                    
                    VStack(spacing: RCSpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }
                        
                        Text("Demo video would play here")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(Color.rcSurface)
            .navigationTitle("How to Photograph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.rcPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
