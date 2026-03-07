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
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Demo video button
                if flowState.policy?.demoVideoUrl != nil {
                    demoVideoButton
                }
                
                // Photo guidelines
                guidelinesSection
                
                // Photo capture area
                photoCaptureSection
                
                // Photo preview grid
                if !flowState.capturedPhotos.isEmpty {
                    photoPreviewGrid
                }
                
                // Upload progress
                if flowState.isLoading {
                    uploadProgressView
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
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
        VStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Photo Verification")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Take \(requiredPhotoCount) photos of your item")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<requiredPhotoCount, id: \.self) { index in
                    Circle()
                        .fill(index < flowState.capturedPhotos.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 8)
        }
        .padding(.top)
    }
    
    private var demoVideoButton: some View {
        Button {
            showDemoVideo = true
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text("Watch: How to photograph your item")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showDemoVideo) {
            DemoVideoView()
        }
    }
    
    private var guidelinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo Guidelines")
                .font(.headline)
            
            GuidelineRow(icon: "1.circle.fill", text: "Front view - entire item visible")
            GuidelineRow(icon: "2.circle.fill", text: "Back/underside - show all angles")
            GuidelineRow(icon: "3.circle.fill", text: "Close-up of any damage or wear")
            
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Good lighting helps us assess faster")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var photoCaptureSection: some View {
        VStack(spacing: 16) {
            // Camera button
            Button {
                showingCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Take Photo")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Photo library button
            Button {
                showingImagePicker = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                    Text("Choose from Library")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    private var photoPreviewGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Photos")
                    .font(.headline)
                Spacer()
                Text("\(flowState.capturedPhotos.count)/\(requiredPhotoCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(flowState.capturedPhotos.indices, id: \.self) { index in
                    PhotoPreviewCell(
                        imageData: flowState.capturedPhotos[index],
                        onDelete: {
                            withAnimation {
                                flowState.capturedPhotos.remove(at: index)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var uploadProgressView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Analyzing photos...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
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
                    .cornerRadius(8)
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(4)
        }
    }
}

struct DemoVideoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Placeholder for video player
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                            Text("Demo video would play here")
                                .foregroundColor(.white)
                        }
                    )
                    .cornerRadius(12)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("How to Photograph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
