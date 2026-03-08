import SwiftUI
import PhotosUI
import AVKit

/// Screen 3: Capture photos/video of item condition
struct PhotoCaptureView: View {
    @ObservedObject var flowState: ReturnFlowState
    var onDemoSelected: (() -> Void)? = nil  // called after demo image loads to auto-advance

    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showDemoVideo = false

    private let requiredPhotoCount = 3

    // Demo sofa images — loaded for convenience; score is hardcoded by demoScoreOverride
    private let sofaUrl1 = "https://res.cloudinary.com/dyrit94wr/image/upload/v1772961956/demo_poor_sofa.webp"
    private let sofaUrl2 = "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=80"
    @State private var loadingDemo: String? = nil  // "1" | "2" | nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: RCSpacing.xl) {
                // Header
                headerSection
                    .slideIn(delay: 0.1)
                
                // Packaging video button — item-specific, falls back to store-level
                if flowState.selectedItem?.packagingVideoUrl != nil || flowState.policy?.demoVideoUrl != nil {
                    packagingVideoButton
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
    
    private var packagingVideoButton: some View {
        Button {
            showDemoVideo = true
        } label: {
            HStack(spacing: RCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.rcPrimary.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.rcPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("How to package \(flowState.selectedItem?.title ?? "your item")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.rcTextPrimary)
                    Text("Watch the packaging guide before shipping")
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
            PackagingVideoView(
                videoUrl: flowState.selectedItem?.packagingVideoUrl ?? flowState.policy?.demoVideoUrl,
                itemTitle: flowState.selectedItem?.title ?? "Your Item"
            )
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

            // Demo image tiles — tap to select and auto-advance
            if flowState.capturedPhotos.isEmpty {
                VStack(alignment: .leading, spacing: RCSpacing.sm) {
                    Text("Or pick a demo photo")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.rcTextMuted)
                    HStack(spacing: RCSpacing.sm) {
                        demoImageTile(url: sofaUrl1, score: 15, key: "1")
                        demoImageTile(url: sofaUrl2, score: 95, key: "2")
                    }
                }
            }
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

    @ViewBuilder
    private func demoImageTile(url: String, score: Int, key: String) -> some View {
        Button {
            RCHaptics.impact(.medium)
            Task { await loadDemo(url: url, score: score, key: key) }
        } label: {
            ZStack {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.rcSurfaceMuted
                    default:
                        Color.rcSurfaceMuted.overlay(ProgressView().scaleEffect(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .clipped()
                .cornerRadius(RCRadius.lg)

                if loadingDemo == key {
                    RoundedRectangle(cornerRadius: RCRadius.lg)
                        .fill(Color.black.opacity(0.4))
                    ProgressView().tint(.white)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: RCRadius.lg)
                    .stroke(Color.rcBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(loadingDemo != nil)
    }

    private func loadDemo(url: String, score: Int, key: String) async {
        await MainActor.run { loadingDemo = key }
        guard let imageUrl = URL(string: url),
              let (data, _) = try? await URLSession.shared.data(from: imageUrl) else {
            await MainActor.run { loadingDemo = nil }
            return
        }
        await MainActor.run {
            flowState.capturedPhotos = [data]
            flowState.demoScoreOverride = score
            loadingDemo = nil
            onDemoSelected?()
        }
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

struct PackagingVideoView: View {
    @Environment(\.dismiss) var dismiss
    var videoUrl: String?
    var itemTitle: String

    private var resolvedVideoUrl: URL? {
        let urlString = videoUrl ?? "https://res.cloudinary.com/demo/video/upload/q_auto,f_auto/docs/cld-sample-video.mp4"
        return URL(string: urlString)
    }

    @StateObject private var playerHolder = AVPlayerHolder()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let url = resolvedVideoUrl {
                    VideoPlayer(player: playerHolder.player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(RCRadius.lg)
                        .padding(.horizontal, RCSpacing.lg)
                        .padding(.top, RCSpacing.lg)
                        .onAppear {
                            playerHolder.load(url: url)
                            playerHolder.player.play()
                        }
                        .onDisappear {
                            playerHolder.player.pause()
                        }
                } else {
                    placeholderView
                }

                VStack(alignment: .leading, spacing: RCSpacing.md) {
                    Text("Packaging Tips")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.rcTextPrimary)

                    GuidelineRow(icon: "box.fill", text: "Use the original packaging if available", color: .rcPrimary)
                    GuidelineRow(icon: "sparkles", text: "Wrap fragile parts individually", color: .rcWarning)
                    GuidelineRow(icon: "seal.fill", text: "Seal the box securely on all sides", color: .rcPrimary)
                    GuidelineRow(icon: "checkmark.circle.fill", text: "Attach the return label to the outside", color: .rcSuccess)
                }
                .rcCard()
                .padding(.horizontal, RCSpacing.lg)
                .padding(.top, RCSpacing.lg)

                HStack(spacing: RCSpacing.xs) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 11))
                    Text("Video served via Cloudinary CDN")
                        .font(.system(size: 11))
                }
                .foregroundColor(.rcTextMuted)
                .padding(.top, RCSpacing.md)

                Spacer()
            }
            .background(Color.rcSurface)
            .navigationTitle("Package \(itemTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.rcPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RCRadius.lg)
                .fill(Color.black)
                .aspectRatio(16/9, contentMode: .fit)
            VStack(spacing: RCSpacing.md) {
                Image(systemName: "video.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
                Text("No packaging video configured")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, RCSpacing.lg)
        .padding(.top, RCSpacing.lg)
    }
}

/// Holds the AVPlayer instance so it persists across view updates
final class AVPlayerHolder: ObservableObject {
    let player = AVPlayer()

    func load(url: URL) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
    }
}
