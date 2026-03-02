import SwiftUI
import Speech
import Combine

struct LectureView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var transcription = TranscriptionManager.shared
    @State private var appear = false
    @State private var showSummary = false
    @State private var summary = ""
    @State private var isGeneratingSummary = false
    @State private var lectureTitle = ""
    @State private var showTitlePrompt = false
    @State private var finalText = ""
    @State private var wavePhase = 0.0
    @State private var pulseScale = 1.0
    @State private var savedTranscripts: [[String: String]] = []
    @State private var showTranscripts = false
    
    let waveTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let pulseTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Animated background when recording
            if transcription.isRecording {
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.red.opacity(0.03 - Double(i) * 0.008))
                            .frame(width: CGFloat(200 + i * 100))
                            .scaleEffect(pulseScale + Double(i) * 0.1)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: pulseScale
                            )
                    }
                }
            }
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: {
                        if transcription.isRecording {
                            _ = transcription.stopRecording()
                        }
                        appState.currentView = .home
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Vexom Lecture")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showTranscripts = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                if showSummary {
                    summaryView
                } else {
                    transcriptionView
                }
            }
            
            // Title prompt overlay
            if showTitlePrompt {
                titlePromptView
            }
        }
        .onAppear {
            appear = true
            pulseScale = 1.05
            savedTranscripts = UserDefaults.standard.array(forKey: "vexom_transcripts") as? [[String: String]] ?? []
        }
        .onReceive(waveTimer) { _ in
            wavePhase += 0.1
        }
        .onReceive(pulseTimer) { _ in
            if transcription.isRecording {
                pulseScale = pulseScale == 1.0 ? 1.05 : 1.0
            }
        }
        .sheet(isPresented: $showTranscripts) {
            transcriptsSheet
        }
    }
    
    // MARK: - Transcription View
    var transcriptionView: some View {
        VStack(spacing: 0) {
            // Status header
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if transcription.isRecording {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseScale)
                            .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulseScale)
                        Text("Recording")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        Text("Ready to record")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                
                if transcription.isRecording {
                    Text("Listening to your lecture...")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 20)
            
            // Waveform visualizer
            waveformView
                .frame(height: 80)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            
            // Transcript area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if transcription.transcribedText.isEmpty && transcription.interimText.isEmpty && !transcription.isRecording {
                            // Empty state
                            VStack(spacing: 16) {
                                Text("🎙️")
                                    .font(.system(size: 48))
                                Text("Tap record to start\ntranscribing your lecture")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    featurePill(icon: "waveform", text: "Real-time transcription")
                                    featurePill(icon: "brain", text: "AI summary after class")
                                    featurePill(icon: "list.bullet", text: "Key concepts extracted")
                                    featurePill(icon: "lock.fill", text: "Processed on your device")
                                }
                                .padding(.top, 10)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            // Transcribed text
                            Text(transcription.transcribedText)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(.bottom, 4)
                            
                            // Interim (live) text
                            Text(transcription.interimText)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.4))
                                .id("bottom")
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: transcription.interimText) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
            .padding(.horizontal, 20)
            
            Spacer(minLength: 20)
            
            // Bottom controls
            VStack(spacing: 16) {
                // Word count
                if !transcription.transcribedText.isEmpty {
                    Text("\(wordCount) words transcribed")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 20) {
                    // Stop + summarize button
                    if transcription.isRecording || !transcription.transcribedText.isEmpty {
                        Button(action: stopAndSummarize) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                Text("Stop & Summarize")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.purple.opacity(0.8))
                            .cornerRadius(16)
                        }
                    }
                    
                    // Record button
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(transcription.isRecording ? Color.red : Color.white)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .stroke(
                                    transcription.isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.3),
                                    lineWidth: 3
                                )
                                .frame(width: 84, height: 84)
                                .scaleEffect(transcription.isRecording ? pulseScale + 0.1 : 1.0)
                            
                            Image(systemName: transcription.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 24))
                                .foregroundColor(transcription.isRecording ? .white : .black)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Waveform
    var waveformView: some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(0..<40, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(transcription.isRecording ? Color.red.opacity(0.8) : Color.white.opacity(0.2))
                        .frame(width: (geo.size.width - 120) / 40)
                        .frame(height: transcription.isRecording ?
                               abs(sin(wavePhase + Double(i) * 0.4)) * 50 + 4 :
                               4
                        )
                        .animation(
                            transcription.isRecording ?
                                .easeInOut(duration: 0.3).delay(Double(i) * 0.02) :
                                .easeOut(duration: 0.3),
                            value: wavePhase
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Summary View
    var summaryView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lectureTitle.isEmpty ? "Lecture Notes" : lectureTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(Date(), style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    showSummary = false
                    transcription.transcribedText = ""
                    transcription.interimText = ""
                }) {
                    Text("New")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            if isGeneratingSummary {
                VStack(spacing: 20) {
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.purple.opacity(0.2), lineWidth: 3)
                            .frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.purple, lineWidth: 3)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(wavePhase * 10))
                    }
                    Text("Generating your summary...")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Text("Vexom is analyzing your lecture")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary content
                        Text(summary.isEmpty ? "No summary available" : summary)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(16)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(16)
                        
                        // Original transcript toggle
                        DisclosureGroup {
                            Text(finalText)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)
                        } label: {
                            Text("View full transcript")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(16)
                        .accentColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            
            if !isGeneratingSummary {
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        UIPasteboard.general.string = summary
                        HapticEngine.shared.playSuccess()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 13))
                            Text("Copy")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                    }
                    
                    Button(action: sendToChat) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 13))
                            Text("Ask Vexom")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Title Prompt
    var titlePromptView: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Name this lecture")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Give it a title so you can find it later")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                TextField("e.g. CSCI C212 - Week 7", text: $lectureTitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Button(action: {
                        showTitlePrompt = false
                        generateSummaryNow()
                    }) {
                        Text("Skip")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                    }
                    
                    Button(action: {
                        showTitlePrompt = false
                        generateSummaryNow()
                    }) {
                        Text("Save & Summarize")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(24)
            .background(Color(white: 0.1))
            .cornerRadius(24)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Transcripts Sheet
    var transcriptsSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if savedTranscripts.isEmpty {
                    VStack(spacing: 12) {
                        Text("🎙️")
                            .font(.system(size: 40))
                        Text("No saved lectures yet")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(savedTranscripts, id: \.["id"]) { transcript in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(transcript["title"] ?? "Untitled")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                Text(transcript["summary"]?.prefix(80) ?? "")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                if let dateStr = transcript["date"],
                                   let date = ISO8601DateFormatter().date(from: dateStr) {
                                    Text(date, style: .relative)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color.white.opacity(0.04))
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.black)
                }
            }
            .navigationTitle("Past Lectures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showTranscripts = false }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helper Views
    func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.purple)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Actions
    func toggleRecording() {
        HapticEngine.shared.playGoalSelect()
        if transcription.isRecording {
            stopAndSummarize()
        } else {
            transcription.startRecording()
        }
    }
    
    func stopAndSummarize() {
        finalText = transcription.stopRecording()
        guard !finalText.isEmpty else { return }
        HapticEngine.shared.playSuccess()
        showTitlePrompt = true
    }
    
    func generateSummaryNow() {
        showSummary = true
        isGeneratingSummary = true
        
        Task {
            let generatedSummary = await TranscriptionManager.shared.generateSummary(text: finalText)
            await MainActor.run {
                summary = generatedSummary
                isGeneratingSummary = false
                
                // Save transcript
                let title = lectureTitle.isEmpty ? "Lecture \(Date().formatted(date: .abbreviated, time: .omitted))" : lectureTitle
                TranscriptionManager.shared.saveTranscript(title: title, text: finalText, summary: generatedSummary)
                savedTranscripts = UserDefaults.standard.array(forKey: "vexom_transcripts") as? [[String: String]] ?? []
            }
        }
    }
    
    func sendToChat() {
        UserDefaults.standard.set("Summarize this lecture: \(summary)", forKey: "pending_chat_text")
        appState.currentView = .chat
    }
    
    var wordCount: Int {
        transcription.transcribedText.split(separator: " ").count
    }
}
