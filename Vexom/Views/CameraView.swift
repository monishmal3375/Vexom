import SwiftUI
import AVFoundation
import Vision
import Combine

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var camera = CameraModel()
    @State private var showResult = false
    @State private var pendingResult: IntelligenceResult? = nil
    @State private var isScanning = false
    @State private var scanProgress = false
    
    var body: some View {
        ZStack {
            // Camera feed
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            // Dark overlay with scan window
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .mask(
                        Rectangle()
                            .ignoresSafeArea()
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: 320, height: 220)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Scan frame
                RoundedRectangle(cornerRadius: 16)
                    .stroke(scanProgress ? Color.green : Color.white, lineWidth: 2)
                    .frame(width: 320, height: 220)
                    .animation(.easeInOut(duration: 0.3), value: scanProgress)
                
                // Corner accents
                VStack {
                    HStack {
                        cornerAccent(rotation: 0)
                        Spacer()
                        cornerAccent(rotation: 90)
                    }
                    Spacer()
                    HStack {
                        cornerAccent(rotation: 270)
                        Spacer()
                        cornerAccent(rotation: 180)
                    }
                }
                .frame(width: 320, height: 220)
                
                // Scanning line animation
                if isScanning {
                    Rectangle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 300, height: 2)
                        .offset(y: scanProgress ? 100 : -100)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scanProgress)
                }
            }
            
            // UI overlay
            VStack {
                // Top bar
                HStack {
                    Button(action: { appState.currentView = .home }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Vexom Vision")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    // Torch button
                    Button(action: { camera.toggleTorch() }) {
                        Image(systemName: camera.torchOn ? "bolt.fill" : "bolt.slash")
                            .foregroundColor(camera.torchOn ? .yellow : .white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Hint text
                Text(hintText)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                
                // Mode pills
                HStack(spacing: 10) {
                    ForEach(["Auto", "Card", "Meeting", "Notes"], id: \.self) { mode in
                        Text(mode)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(camera.selectedMode == mode ? .black : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(camera.selectedMode == mode ? Color.white : Color.white.opacity(0.2))
                            .cornerRadius(20)
                            .onTapGesture { camera.selectedMode = mode }
                    }
                }
                .padding(.bottom, 20)
                
                // Capture button
                Button(action: { captureAndAnalyze() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 3)
                            .frame(width: 84, height: 84)
                        if isScanning {
                            ProgressView()
                                .tint(.black)
                                .scaleEffect(1.2)
                        }
                    }
                }
                .disabled(isScanning)
                .padding(.bottom, 50)
            }
            
            // Result overlay
            if showResult, let result = pendingResult {
                ActionResultView(result: result) {
                    showResult = false
                    pendingResult = nil
                    isScanning = false
                    scanProgress = false
                }
                .zIndex(999)
            }
        }
        .onAppear {
            camera.start()
        }
        .onDisappear {
            camera.stop()
        }
    }
    
    var hintText: String {
        switch camera.selectedMode {
        case "Card": return "Point at a business card"
        case "Meeting": return "Point at meeting info or Zoom link"
        case "Notes": return "Point at handwritten or printed notes"
        default: return "Point at anything — Vexom figures it out"
        }
    }
    
    func captureAndAnalyze() {
        isScanning = true
        scanProgress = true
        HapticEngine.shared.playGoalSelect()
        
        camera.capturePhoto { image in
            guard let image = image else {
                isScanning = false
                scanProgress = false
                return
            }
            
            VisionManager.shared.recognizeText(from: image) { text in
                guard !text.isEmpty else {
                    isScanning = false
                    scanProgress = false
                    HapticEngine.shared.playError()
                    return
                }
                
                Task {
                    let result = await IntelligenceEngine.shared.analyze(text: text)
                    await MainActor.run {
                        pendingResult = result
                        showResult = true
                        isScanning = false
                        HapticEngine.shared.playSuccess()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func cornerAccent(rotation: Double) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 20))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 20, y: 0))
            }
            .stroke(Color.white, lineWidth: 3)
        }
        .rotationEffect(.degrees(rotation))
        .frame(width: 20, height: 20)
        .padding(8)
    }
}

// MARK: - Camera Model
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var torchOn = false
    @Published var selectedMode = "Auto"
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var photoCompletion: ((UIImage?) -> Void)?
    
    func start() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized ||
              AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined else { return }
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                self.setupSession()
            }
        }
    }
    
    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        
        session.commitConfiguration()
        session.startRunning()
    }
    
    func stop() {
        session.stopRunning()
    }
    
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        torchOn.toggle()
        device.torchMode = torchOn ? .on : .off
        device.unlockForConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCompletion?(nil)
            return
        }
        photoCompletion?(image)
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let preview = AVCaptureVideoPreviewLayer(session: camera.session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        view.layer.addSublayer(preview)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
