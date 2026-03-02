import Foundation
import Speech
import AVFoundation
import Combine

class TranscriptionManager: NSObject, ObservableObject {
    
    static let shared = TranscriptionManager()
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var interimText = ""
    @Published var authorized = false
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    
    override init() {
        super.init()
        requestPermissions()
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorized = status == .authorized
            }
        }
    }
    
    func startRecording() {
        guard authorized else { requestPermissions(); return }
        guard !isRecording else { return }
        
        // Reset
        transcribedText = ""
        interimText = ""
        
        do {
            try startSession()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("Recording error: \(error)")
        }
    }
    
    func startSession() throws {
        // Cancel existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Input node
        let inputNode = audioEngine.inputNode
        
        // Recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    if result.isFinal {
                        self.transcribedText += result.bestTranscription.formattedString + " "
                        self.interimText = ""
                    } else {
                        self.interimText = result.bestTranscription.formattedString
                    }
                }
                
                // Reset silence timer
                self.silenceTimer?.invalidate()
                self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
                    // Auto restart after 60s to bypass Apple's limit
                    if self.isRecording {
                        self.restartSession()
                    }
                }
            }
            
            if let error = error {
                print("Recognition error: \(error)")
                if self.isRecording {
                    self.restartSession()
                }
            }
        }
        
        // Audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func restartSession() {
        // Save current interim text
        if !interimText.isEmpty {
            transcribedText += interimText + " "
            interimText = ""
        }
        
        // Stop current session
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Restart after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            try? self.startSession()
        }
    }
    
    func stopRecording() -> String {
        silenceTimer?.invalidate()
        isRecording = false
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        try? AVAudioSession.sharedInstance().setActive(false)
        
        let finalText = transcribedText + interimText
        return finalText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func saveTranscript(title: String, text: String, summary: String) {
        var transcripts = UserDefaults.standard.array(forKey: "vexom_transcripts") as? [[String: String]] ?? []
        let transcript: [String: String] = [
            "id": UUID().uuidString,
            "title": title,
            "text": text,
            "summary": summary,
            "date": ISO8601DateFormatter().string(from: Date())
        ]
        transcripts.insert(transcript, at: 0)
        UserDefaults.standard.set(transcripts, forKey: "vexom_transcripts")
    }
    
    func generateSummary(text: String) async -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return "" }
        
        let apiKey = "YOUR_ANTHROPIC_API_KEY"
        
        let prompt = """
        You are a study assistant. Summarize this lecture transcript for a college student.
        
        Format your response as:
        ## Summary
        2-3 sentence overview
        
        ## Key Concepts
        - concept 1
        - concept 2
        - concept 3
        
        ## Important Details
        - detail 1
        - detail 2
        
        ## Study Tips
        1-2 things to focus on
        
        Transcript:
        \(text)
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1000,
            "messages": [["role": "user", "content": prompt]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            return response.content.first?.text ?? ""
        } catch {
            return "Summary unavailable"
        }
    }
}
