import SwiftUI
import Combine
import AVFoundation
import AVKit
import PhotosUI
import PencilKit
import CoreML

// MARK: - App Entry

#if ROKMAX_APP
@main
#endif
struct RokMaxCreativeApp: App {
    @StateObject private var appModel: AppModel

    init() {
        let uiTestMode = ProcessInfo.processInfo.environment["DEARTSWCS_UI_TEST_MODE"] == "1"
        _appModel = StateObject(wrappedValue: AppModel(uiTestMode: uiTestMode))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}

// MARK: - App Model

final class AppModel: ObservableObject {
    @Published var selectedTab: CreativeTab = .home
    @Published var generatedImages: [UIImage] = []
    @Published var savedPaintings: [UIImage] = []
    @Published var capturedPhotos: [UIImage] = []
    @Published var recordedVideoURL: URL?
    @Published var linkedMemories: [LinkedMediaMemory] = []
    @Published var mediaEdges: [MediaEdge] = []
    @Published var statusMessage: String = "Welcome"
    @Published var isOfflineMode: Bool = false
    @Published var moodValue: Double = 0.5

    let imageGenerator = TextToImageService()
    let mediaRecorder = MediaRecorderService()
    let paintingStore = PaintingStore()

    init(uiTestMode: Bool = false) {
        if uiTestMode {
            applyUITestSeedData()
        }
    }

    func addGeneratedImage(_ image: UIImage, prompt: String) {
        generatedImages.insert(image, at: 0)
        addMemory(kind: .generatedImage, image: image, videoURL: nil, prompt: prompt, source: "OpenAI/Apple")
        statusMessage = "Created a new calming image"
    }

    func addCapturedPhoto(_ image: UIImage) {
        capturedPhotos.insert(image, at: 0)
        addMemory(kind: .capturedPhoto, image: image, videoURL: nil, prompt: nil, source: "AVFoundation")
        statusMessage = "Captured a photo"
    }

    func addPainting(_ image: UIImage) {
        savedPaintings.insert(image, at: 0)
        addMemory(kind: .painting, image: image, videoURL: nil, prompt: nil, source: "PencilKit")
        statusMessage = "Saved a painting"
    }

    func addRecordedVideo(_ url: URL) {
        recordedVideoURL = url
        let thumbnail = LinkedMediaMemory.videoThumbnail(from: url)
        addMemory(kind: .recordedVideo, image: thumbnail, videoURL: url, prompt: nil, source: "AVFoundation")
        statusMessage = "Saved a video memory"
    }

    func edgeCount(for memoryID: UUID) -> Int {
        mediaEdges.filter { $0.fromID == memoryID || $0.toID == memoryID }.count
    }

    private func addMemory(kind: LinkedMediaMemory.Kind, image: UIImage?, videoURL: URL?, prompt: String?, source: String) {
        let memory = LinkedMediaMemory(kind: kind, image: image, videoURL: videoURL, prompt: prompt, source: source)
        if let nearest = linkedMemories.first {
            mediaEdges.insert(MediaEdge(fromID: memory.id, toID: nearest.id, relation: .timelineAdjacent), at: 0)
        }
        linkedMemories.insert(memory, at: 0)
    }

    private func applyUITestSeedData() {
        statusMessage = "Session Started"
        selectedTab = .home
        isOfflineMode = false
        moodValue = 0.5

        let generated = Self.makeSolidImage(color: .systemTeal)
        let photo = Self.makeSolidImage(color: .systemBlue)
        let painting = Self.makeSolidImage(color: .systemOrange)

        generatedImages = [generated]
        capturedPhotos = [photo]
        savedPaintings = [painting]

        linkedMemories = [
            LinkedMediaMemory(kind: .painting, image: painting, videoURL: nil, prompt: nil, source: "PencilKit"),
            LinkedMediaMemory(kind: .capturedPhoto, image: photo, videoURL: nil, prompt: nil, source: "AVFoundation"),
            LinkedMediaMemory(kind: .generatedImage, image: generated, videoURL: nil, prompt: "UI test seed", source: "OpenAI/Apple")
        ]
    }

    private static func makeSolidImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
        }
    }
}

struct LinkedMediaMemory: Identifiable {
    enum Kind: String {
        case generatedImage
        case capturedPhoto
        case painting
        case recordedVideo
    }

    let id = UUID()
    let createdAt = Date()
    let kind: Kind
    let image: UIImage?
    let videoURL: URL?
    let prompt: String?
    let source: String

    static func videoThumbnail(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct MediaEdge: Identifiable {
    enum Relation: String {
        case timelineAdjacent
    }

    let id = UUID()
    let fromID: UUID
    let toID: UUID
    let relation: Relation
}

enum CreativeTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case imagine = "Imagine"
    case camera = "Camera"
    case paint = "Paint"
    case memories = "Memories"

    var id: String { rawValue }
}

// MARK: - Root UI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(CreativeTab.home)

            ImagineView()
                .tabItem { Label("Imagine", systemImage: "sparkles") }
                .tag(CreativeTab.imagine)

            CameraStudioView()
                .tabItem { Label("Camera", systemImage: "camera") }
                .tag(CreativeTab.camera)

            PaintingStudioView()
                .tabItem { Label("Paint", systemImage: "pencil.and.scribble") }
                .tag(CreativeTab.paint)

            MemoriesView()
                .tabItem { Label("Memories", systemImage: "photo.on.rectangle") }
                .tag(CreativeTab.memories)
        }
        .tint(.purple)
        .accessibilityIdentifier("rootTabView")
    }
}

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showCaregiverDashboard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Rok Max Creative Care")
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("homeTitleLabel")

                    Text("A calm, dementia-friendly creative space for painting, gentle image generation, memory prompts, and capturing photos or videos.")
                        .font(.body)

                    Label(model.statusMessage, systemImage: "heart.text.square")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier("sessionStartedLabel")

                    Text("You created ocean waves today.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("sessionNarrativeLabel")

                    Button {
                        model.statusMessage = "Session Started"
                    } label: {
                        Label("Start Therapy", systemImage: "play.circle.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("startTherapyButton")

                    Button {
                        showCaregiverDashboard = true
                    } label: {
                        Label("Caregiver Dashboard", systemImage: "person.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("caregiverDashboardEntry")

                    Toggle("Offline Mode", isOn: $model.isOfflineMode)
                        .accessibilityIdentifier("offlineToggle")

                    if model.isOfflineMode {
                        Label("Offline mode active", systemImage: "wifi.slash")
                            .accessibilityIdentifier("offlineModeIndicator")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                        Slider(value: $model.moodValue, in: 0...1)
                            .accessibilityIdentifier("moodSlider")

                        if model.moodValue >= 0.66 {
                            Text("Ambient: Happy")
                                .accessibilityIdentifier("ambientStateHappy")
                        } else if model.moodValue <= 0.33 {
                            Text("Ambient: Calm")
                                .accessibilityIdentifier("ambientStateCalm")
                        } else {
                            Text("Ambient: Focus")
                                .accessibilityIdentifier("ambientStateFocus")
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Care design goals")
                            .font(.title3.bold())
                        DementiaFriendlyBullet(text: "Large buttons and calm wording.")
                        DementiaFriendlyBullet(text: "One main action per screen.")
                        DementiaFriendlyBullet(text: "Audio, image, and video prompts for reminiscence therapy.")
                        DementiaFriendlyBullet(text: "Canvas painting with simple save and share flow.")
                    }
                }
                .padding()
            }
            .navigationTitle("Creative Care")
            .accessibilityIdentifier("homeRoot")
            .sheet(isPresented: $showCaregiverDashboard) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Caregiver Dashboard")
                            .font(.title.bold())
                        Text("Live mood trend graphs and session summaries.")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .accessibilityIdentifier("caregiverDashboardRoot")
                }
            }
        }
    }
}

struct DementiaFriendlyBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.purple)
                .padding(.top, 6)
            Text(text)
                .font(.title3)
        }
    }
}

// MARK: - Text to Image

struct ImagineView: View {
    @EnvironmentObject private var model: AppModel
    @State private var prompt = "A peaceful garden with bright flowers and warm sunlight"
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Imagine a gentle memory")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Describe a calming image", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("imaginePromptField")

                Button {
                    Task {
                        isGenerating = true
                        defer { isGenerating = false }
                        if let image = await model.imageGenerator.generateImage(from: prompt) {
                              model.addGeneratedImage(image, prompt: prompt)
                        } else {
                            model.statusMessage = "Image generation is not available yet"
                        }
                    }
                } label: {
                    Label(isGenerating ? "Creating..." : "Create Image", systemImage: "wand.and.stars")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("createImageButton")

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(model.generatedImages.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
                .accessibilityIdentifier("generatedImageList")
            }
            .padding()
            .navigationTitle("Text to Image")
            .accessibilityIdentifier("imagineRoot")
        }
    }
}

actor TextToImageService {
    private let openAIService = OpenAIImageService()

    func generateImage(from prompt: String) async -> UIImage? {
        // Prefer network generation when OPENAI_API_KEY is available, with local fallback.
        if let remote = await openAIService.generateImage(from: prompt) {
            return remote
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        return renderer.image { context in
            UIColor.systemPurple.withAlphaComponent(0.15).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 512, height: 512))

            let text = NSString(string: prompt)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: UIColor.darkText
            ]
            text.draw(in: CGRect(x: 24, y: 180, width: 464, height: 160), withAttributes: attributes)
        }
    }
}

actor OpenAIImageService {
    func generateImage(from prompt: String) async -> UIImage? {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty else {
            return nil
        }
        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": "gpt-image-1",
            "prompt": prompt,
            "size": "1024x1024"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200 ..< 300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]],
              let first = items.first
        else {
            return nil
        }

        if let b64 = first["b64_json"] as? String,
           let imageData = Data(base64Encoded: b64),
           let image = UIImage(data: imageData) {
            return image
        }

        if let imageURLString = first["url"] as? String,
           let imageURL = URL(string: imageURLString),
           let imageData = try? Data(contentsOf: imageURL),
           let image = UIImage(data: imageData) {
            return image
        }

        return nil
    }
}

// MARK: - Camera and Video

struct CameraStudioView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var camera = CameraViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                CameraPreviewView(session: camera.session)
                    .frame(height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityIdentifier("cameraPreview")

                HStack(spacing: 16) {
                    Button {
                        camera.capturePhoto()
                    } label: {
                        Label("Photo", systemImage: "camera.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("capturePhotoButton")

                    Button {
                        camera.isRecording ? camera.stopRecording() : camera.startRecording()
                    } label: {
                        Label(camera.isRecording ? "Stop Video" : "Record Video", systemImage: camera.isRecording ? "stop.circle.fill" : "video.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("recordVideoButton")
                }
                .font(.title3.bold())

                if let image = camera.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let videoURL = camera.recordedVideoURL {
                    Text("Saved video: \(videoURL.lastPathComponent)")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("savedVideoLabel")
                }
            }
            .padding()
            .navigationTitle("Camera Studio")
            .accessibilityIdentifier("cameraRoot")
            .task {
                await camera.requestPermissionsAndStart()
            }
            .onChange(of: camera.capturedImage) { image in
                if let image {
                      model.addCapturedPhoto(image)
                }
            }
            .onChange(of: camera.recordedVideoURL) { url in
                  if let url {
                      model.addRecordedVideo(url)
                }
            }
        }
    }
}

final class CameraViewModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var isSessionConfigured = false
    private var isRecordingStartPending = false

    @Published var capturedImage: UIImage?
    @Published var recordedVideoURL: URL?
    @Published var isRecording = false

    func requestPermissionsAndStart() async {
        let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        let micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        guard cameraGranted, micGranted else { return }
        configureSession()
    }

    func configureSession() {
        sessionQueue.async {
            guard self.videoDeviceInput == nil else {
                if !self.session.isRunning { self.session.startRunning() }
                self.isSessionConfigured = true
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            defer {
                self.session.commitConfiguration()
                if !self.session.isRunning { self.session.startRunning() }
            }

            guard
                let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let audioDevice = AVCaptureDevice.default(for: .audio),
                let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
            else { return }

            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
                self.videoDeviceInput = videoInput
            }

            if self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                // Set delegate during configuration
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.isSessionConfigured = true
        }
    }

    func capturePhoto() {
        sessionQueue.async {
            guard self.isSessionConfigured else { return }
            guard self.session.isRunning else { return }
            guard !self.isRecordingStartPending else { return }
            guard !self.movieOutput.isRecording else { return }
            guard let photoConnection = self.photoOutput.connection(with: .video), photoConnection.isEnabled else { return }
            let settings = AVCapturePhotoSettings()
            if self.photoOutput.isHighResolutionCaptureEnabled {
                settings.isHighResolutionPhotoEnabled = true
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func startRecording() {
        sessionQueue.async {
            guard self.isSessionConfigured else { return }
            guard self.session.isRunning else { return }
            guard !self.isRecordingStartPending else { return }
            guard !self.movieOutput.isRecording else { return }
            guard let videoConnection = self.movieOutput.connection(with: .video), videoConnection.isEnabled else { return }

            self.isRecordingStartPending = true
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
            DispatchQueue.main.async { self.isRecording = true }
        }
    }

    func stopRecording() {
        sessionQueue.async {
            guard !self.isRecordingStartPending else { return }
            guard self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
            DispatchQueue.main.async { self.isRecording = false }
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        sessionQueue.async {
            self.isRecordingStartPending = false
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        sessionQueue.async {
            self.isRecordingStartPending = false
        }
        DispatchQueue.main.async {
            self.recordedVideoURL = outputFileURL
            self.isRecording = false
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

final class MediaRecorderService {
    // Extend with audio recording, playback, waveform, and background uploads.
}

final class PaintingStore {}

// MARK: - Painting Studio

struct PaintingStudioView: View {
    @EnvironmentObject private var model: AppModel
    @State private var exportedImage: UIImage?
    @State private var exportRequested = false
    @State private var clearRequested = false
    @State private var isCanvasEmpty = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paint with color and memory")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                DementiaFriendlyCanvasView(
                    exportedImage: $exportedImage,
                    exportRequested: $exportRequested,
                    clearRequested: $clearRequested,
                    isCanvasEmpty: $isCanvasEmpty
                )
                .frame(height: 420)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                .accessibilityIdentifier("therapyCanvas")

                HStack(spacing: 16) {
                    Button {
                        exportRequested = true
                    } label: {
                        Label("Save Painting", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCanvasEmpty)
                    .accessibilityIdentifier("savePaintingButton")

                    Button {
                        clearRequested = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("clearCanvasButton")
                }
                .font(.title3.bold())

                if let exportedImage {
                    Image(uiImage: exportedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onAppear {
                              model.addPainting(exportedImage)
                        }
                        .accessibilityIdentifier("savedPaintingPreview")
                }
            }
            .padding()
            .navigationTitle("Canvas Painting")
            .accessibilityIdentifier("paintRoot")
        }
    }
}

struct DementiaFriendlyCanvasView: UIViewRepresentable {
    @Binding var exportedImage: UIImage?
    @Binding var exportRequested: Bool
    @Binding var clearRequested: Bool
    @Binding var isCanvasEmpty: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isCanvasEmpty: $isCanvasEmpty)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = UIColor.systemBackground
        canvas.drawingPolicy = .anyInput
        canvas.alwaysBounceVertical = false
        canvas.tool = PKInkingTool(.marker, color: .systemPurple, width: 12)
        canvas.accessibilityIdentifier = "therapyCanvas"
        canvas.delegate = context.coordinator
        context.coordinator.canvasView = canvas
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if exportRequested {
            let bounds = uiView.bounds.insetBy(dx: 0, dy: 0)
            let image = uiView.drawing.image(from: bounds, scale: UIScreen.main.scale)
            DispatchQueue.main.async {
                exportedImage = image
                exportRequested = false
            }
        }

        if clearRequested {
            uiView.drawing = PKDrawing()
            DispatchQueue.main.async {
                clearRequested = false
                isCanvasEmpty = true
            }
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        weak var canvasView: PKCanvasView?
        @Binding var isCanvasEmpty: Bool

        init(isCanvasEmpty: Binding<Bool>) {
            _isCanvasEmpty = isCanvasEmpty
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isCanvasEmpty = canvasView.drawing.strokes.isEmpty
        }
    }
}

// MARK: - Memories

struct MemoriesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !model.linkedMemories.isEmpty {
                        Text("Linked Memory Graph")
                            .font(.title2.bold())
                        Text("Each item is connected by timeline edges and keeps multimedia source metadata.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVStack(spacing: 12) {
                            ForEach(model.linkedMemories) { memory in
                                LinkedMemoryCard(memory: memory, edgeCount: model.edgeCount(for: memory.id))
                            }
                        }
                    }

                    if model.linkedMemories.isEmpty {
                        ContentUnavailableView("No memories yet", systemImage: "photo.stack", description: Text("Create an image, take a photo, or save a painting to build a gentle memory gallery."))
                    }
                }
                .padding()
            }
            .navigationTitle("Memories")
            .accessibilityIdentifier("memoriesRoot")
        }
    }
}

struct GallerySection: View {
    let title: String
    let images: [UIImage]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }
}

struct LinkedMemoryCard: View {
    let memory: LinkedMediaMemory
    let edgeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(memory.kind.rawValue)
                    .font(.headline)
                Spacer()
                Label("\(edgeCount)", systemImage: "point.3.filled.connected.trianglepath.dotted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if memory.kind == .recordedVideo, let videoURL = memory.videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if let image = memory.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if let prompt = memory.prompt {
                Text(prompt)
                    .font(.footnote)
            }

            Text("Source: \(memory.source) • \(memory.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
