import SwiftUI
import CoreHaptics
import CoreMotion
import LocalAuthentication

private let screenWidth: CGFloat = 390
private let screenHeight: CGFloat = 844

// MARK: - Glitch Text
struct GlitchText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var glitching = false
    @State private var glitchOffset1: CGFloat = 0
    @State private var glitchOffset2: CGFloat = 0
    @State private var glitchOpacity1: Double = 0
    @State private var glitchOpacity2: Double = 0
    @State private var displayText: String = ""
    @State private var isResolved = false
    
    let glitchChars = "!@#$%^&*<>?/\\|{}[]~`0123456789ABCDEFX"
    
    var body: some View {
        ZStack {
            // Red channel offset
            Text(displayText)
                .font(font)
                .foregroundColor(.red.opacity(0.7))
                .offset(x: glitchOffset1, y: 0)
                .opacity(glitchOpacity1)
                .blur(radius: 0.5)
            
            // Blue channel offset
            Text(displayText)
                .font(font)
                .foregroundColor(.blue.opacity(0.5))
                .offset(x: -glitchOffset2, y: 1)
                .opacity(glitchOpacity2)
                .blur(radius: 0.5)
            
            // Main text
            Text(displayText)
                .font(font)
                .foregroundColor(color)
        }
        .onAppear {
            startGlitch()
        }
    }
    
    func startGlitch() {
        // Phase 1: scramble
        var scrambleCount = 0
        let maxScrambles = 12
        
        func scrambleStep() {
            guard scrambleCount < maxScrambles else {
                resolveText()
                return
            }
            
            let scrambled = text.map { char -> Character in
                if char == " " || char == "\n" { return char }
                if Double.random(in: 0...1) < 0.6 {
                    return glitchChars.randomElement()!
                }
                return char
            }
            displayText = String(scrambled)
            
            glitchOffset1 = CGFloat.random(in: -4...4)
            glitchOffset2 = CGFloat.random(in: -3...3)
            glitchOpacity1 = Double.random(in: 0.3...0.8)
            glitchOpacity2 = Double.random(in: 0.2...0.6)
            
            scrambleCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                scrambleStep()
            }
        }
        
        scrambleStep()
    }
    
    func resolveText() {
        // Phase 2: resolve letter by letter
        var resolvedCount = 0
        
        func resolveStep() {
            guard resolvedCount <= text.count else {
                displayText = text
                glitchOpacity1 = 0
                glitchOpacity2 = 0
                glitchOffset1 = 0
                glitchOffset2 = 0
                isResolved = true
                return
            }
            
            var result = ""
            for (i, char) in text.enumerated() {
                if char == " " || char == "\n" {
                    result.append(char)
                } else if i < resolvedCount {
                    result.append(char)
                } else {
                    result.append(glitchChars.randomElement()!)
                }
            }
            displayText = result
            
            glitchOffset1 = CGFloat.random(in: -2...2)
            glitchOffset2 = CGFloat.random(in: -1...1)
            glitchOpacity1 = Double.random(in: 0.1...0.4)
            glitchOpacity2 = Double.random(in: 0.1...0.3)
            
            resolvedCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                resolveStep()
            }
        }
        
        resolveStep()
    }
}

// MARK: - Typewriter Effect
struct TypewriterText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .foregroundColor(color)
            .onAppear {
                displayedText = ""
                currentIndex = 0
                typeNextChar()
            }
    }
    
    func typeNextChar() {
        guard currentIndex < text.count else { return }
        let index = text.index(text.startIndex, offsetBy: currentIndex)
        displayedText += String(text[index])
        currentIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            typeNextChar()
        }
    }
}

// MARK: - Parallax Background
struct ParallaxBackground: View {
    @ObservedObject var motion = MotionManager.shared
    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = []
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(particles.prefix(10), id: \.id) { p in
                Circle()
                    .fill(Color.white.opacity(p.opacity * 0.5))
                    .frame(width: p.size * 2, height: p.size * 2)
                    .position(
                        x: p.x + CGFloat(motion.roll * 30),
                        y: animate ? (p.y - 500 + CGFloat(motion.pitch * 20)) : p.y
                    )
                    .animation(.linear(duration: 12).repeatForever(autoreverses: false).delay(Double(p.id) * 0.3), value: animate)
            }
            ForEach(particles.dropFirst(10).prefix(10), id: \.id) { p in
                Circle()
                    .fill(Color.white.opacity(p.opacity))
                    .frame(width: p.size, height: p.size)
                    .position(
                        x: p.x + CGFloat(motion.roll * 15),
                        y: animate ? (p.y - 400 + CGFloat(motion.pitch * 10)) : p.y
                    )
                    .animation(.linear(duration: 9).repeatForever(autoreverses: false).delay(Double(p.id) * 0.2), value: animate)
            }
            ForEach(particles.dropFirst(20), id: \.id) { p in
                Circle()
                    .fill(Color.white.opacity(p.opacity * 1.5))
                    .frame(width: p.size * 0.5, height: p.size * 0.5)
                    .position(
                        x: p.x + CGFloat(motion.roll * 5),
                        y: animate ? (p.y - 300 + CGFloat(motion.pitch * 5)) : p.y
                    )
                    .animation(.linear(duration: 7).repeatForever(autoreverses: false).delay(Double(p.id) * 0.15), value: animate)
            }
        }
        .onAppear {
            particles = (0..<30).map { i in
                (id: i, x: CGFloat.random(in: 0...390), y: CGFloat.random(in: 0...844), size: CGFloat.random(in: 1...4), opacity: Double.random(in: 0.05...0.2))
            }
            animate = true
            MotionManager.shared.start()
        }
    }
}

// MARK: - Particle Burst
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var velocity: CGSize
}

struct ParticleBurst: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text("⚡")
                    .font(.system(size: 16 * particle.scale))
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear { createAndAnimate() }
    }
    
    func createAndAnimate() {
        particles = (0..<20).map { _ in
            Particle(
                x: screenWidth / 2,
                y: screenHeight / 2 - 100,
                scale: CGFloat.random(in: 0.3...1.2),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                velocity: CGSize(width: CGFloat.random(in: -150...150), height: CGFloat.random(in: -250...50))
            )
        }
        withAnimation(.easeOut(duration: 1.5)) {
            for i in particles.indices {
                particles[i].x += particles[i].velocity.width
                particles[i].y += particles[i].velocity.height
                particles[i].opacity = 0
                particles[i].rotation += Double.random(in: 180...360)
                particles[i].scale *= 0.3
            }
        }
    }
}

// MARK: - Main Onboarding
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var phase: OnboardingPhase = .aiIntro
    @State private var name = ""
    @State private var major = ""
    @State private var university = ""
    @State private var goals: [String] = []
    @State private var wakeTime = "7:00 AM"
    @State private var sleepTime = "12:00 AM"
    @State private var currentStep = 0
    @State private var showParticles = false
    
    enum OnboardingPhase {
        case aiIntro
        case permissions
        case setup
        case faceID
    }
    
    let goalOptions = [
        ("🎯", "Land an internship"),
        ("💻", "Build side projects"),
        ("📈", "Grow my network"),
        ("🎓", "Ace my classes"),
        ("💪", "Stay consistent"),
        ("🚀", "Start a company")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ParallaxBackground().ignoresSafeArea()
            
            if showParticles {
                ParticleBurst().ignoresSafeArea().allowsHitTesting(false)
            }
            
            switch phase {
            case .aiIntro:
                AIIntroPhase(onContinue: {
                    HapticEngine.shared.playStepTransition()
                    withAnimation(.easeInOut(duration: 0.6)) { phase = .permissions }
                })
                .transition(.opacity)
                
            case .permissions:
                PermissionsPhase(onContinue: {
                    HapticEngine.shared.playStepTransition()
                    withAnimation(.easeInOut(duration: 0.6)) { phase = .setup }
                })
                .transition(.opacity)
                
            case .setup:
                SetupPhase(
                    currentStep: $currentStep,
                    name: $name,
                    major: $major,
                    university: $university,
                    goals: $goals,
                    wakeTime: $wakeTime,
                    sleepTime: $sleepTime,
                    showParticles: $showParticles,
                    goalOptions: goalOptions,
                    onComplete: {
                        HapticEngine.shared.playStepTransition()
                        withAnimation(.easeInOut(duration: 0.6)) { phase = .faceID }
                    },
                    onSkip: skipOnboarding
                )
                .transition(.opacity)
                
            case .faceID:
                FaceIDPhase(name: name, onComplete: completeOnboarding)
                    .transition(.opacity)
            }
        }
        .onDisappear {
            MotionManager.shared.stop()
        }
    }
    
    func completeOnboarding() {
        HapticEngine.shared.playSuccess()
        UserDefaults.standard.set(name, forKey: "user_name")
        UserDefaults.standard.set(major, forKey: "user_major")
        UserDefaults.standard.set(university, forKey: "user_university")
        UserDefaults.standard.set(goals, forKey: "user_goals")
        UserDefaults.standard.set(wakeTime, forKey: "user_wake_time")
        UserDefaults.standard.set(sleepTime, forKey: "user_sleep_time")
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
        withAnimation { appState.currentView = .home }
    }
    
    func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
        withAnimation { appState.currentView = .home }
    }
}

// MARK: - Face ID Phase
struct FaceIDPhase: View {
    let name: String
    let onComplete: () -> Void
    @State private var appear = false
    @State private var pulse = false
    @State private var scanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var authenticated = false
    @State private var failed = false
    @State private var statusText = "Secure your Vexom"
    @State private var statusSubtext = "Use Face ID to protect your personal AI"
    @State private var rotateRing = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack {
                // Outer rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            authenticated ? Color.green.opacity(0.3 - Double(i) * 0.08) : Color.white.opacity(0.05 - Double(i) * 0.01),
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(120 + i * 50), height: CGFloat(120 + i * 50))
                        .scaleEffect(appear ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.5).delay(Double(i) * 0.1), value: appear)
                        .animation(.easeInOut(duration: 0.5), value: authenticated)
                }
                
                // Rotating dashed ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: authenticated ? [.green.opacity(0.6), .clear] : [.white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(rotateRing ? 360 : 0))
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: rotateRing)
                
                // Scan line
                if scanning {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .green.opacity(0.6), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80, height: 2)
                        .offset(y: scanProgress * 40 - 20)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scanProgress)
                        .clipShape(Circle().scale(0.85))
                }
                
                // Core circle
                Circle()
                    .fill(authenticated ? Color.green.opacity(0.15) : Color.white.opacity(0.06))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulse ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                    .animation(.easeInOut(duration: 0.4), value: authenticated)
                
                // Icon
                Image(systemName: authenticated ? "checkmark" : (failed ? "xmark" : "faceid"))
                    .font(.system(size: authenticated ? 32 : 38, weight: .light))
                    .foregroundColor(authenticated ? .green : (failed ? .red : .white))
                    .scaleEffect(appear ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: appear)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: authenticated)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: failed)
            }
            .padding(.bottom, 40)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: appear)
            
            VStack(spacing: 10) {
                Text(statusText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(authenticated ? .green : .white)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.4), value: statusText)
                
                Text(statusSubtext)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .animation(.easeInOut(duration: 0.4), value: statusSubtext)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: appear)
            
            Spacer()
            
            VStack(spacing: 12) {
                if authenticated {
                    Button(action: onComplete) {
                        HStack {
                            Text("Enter Vexom ⚡")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: authenticate) {
                        HStack(spacing: 8) {
                            Image(systemName: "faceid")
                                .font(.system(size: 16))
                            Text("Authenticate with Face ID")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    
                    Button(action: onComplete) {
                        Text("Skip for now")
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.4), value: appear)
        }
        .onAppear {
            appear = true
            pulse = true
            rotateRing = true
            // Auto-trigger Face ID after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                authenticate()
            }
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // No Face ID available — just skip
            onComplete()
            return
        }
        
        scanning = true
        scanProgress = 1.0
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Secure access to your personal AI"
        ) { success, _ in
            DispatchQueue.main.async {
                scanning = false
                if success {
                    HapticEngine.shared.playSuccess()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        authenticated = true
                        statusText = "Identity confirmed"
                        statusSubtext = "Welcome back, \(name.isEmpty ? "friend" : name) ⚡"
                    }
                    // Auto advance after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete()
                    }
                } else {
                    HapticEngine.shared.playGoalDeselect()
                    withAnimation {
                        failed = true
                        statusText = "Try again"
                        statusSubtext = "Face ID failed. Tap to retry."
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            failed = false
                            statusText = "Secure your Vexom"
                            statusSubtext = "Use Face ID to protect your personal AI"
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Phase A: AI Chat Intro
struct AIIntroPhase: View {
    let onContinue: () -> Void
    
    @State private var messages: [AIMessage] = []
    @State private var showContinue = false
    @State private var appear = false
    @State private var pulse = false
    @State private var isTyping = false
    
    struct AIMessage: Identifiable {
        let id = UUID()
        let text: String
        let isVexom: Bool
        var visible = false
    }
    
    let introMessages: [(String, Bool, Double)] = [
        ("Hey.", true, 0.8),
        ("I've been waiting for you.", true, 2.0),
        ("I'm Vexom.", true, 3.5),
        ("An AI built specifically for ambitious students like you.", true, 5.0),
        ("I'm not like other AI apps.", true, 7.0),
        ("I actually know your life.\nYour calendar. Your messages. Your goals.", true, 8.5),
        ("And I use all of it to tell you what matters right now.", true, 11.0),
        ("But first — I need to learn about you.", true, 13.2),
        ("Ready?", true, 15.0),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                        .scaleEffect(pulse ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 44, height: 44)
                    GlitchText(text: "⚡", font: .system(size: 22), color: .white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    GlitchText(text: "Vexom", font: .system(size: 15, weight: .semibold), color: .white)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .scaleEffect(pulse ? 1.3 : 0.7)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                        Text(isTyping ? "typing..." : "Online")
                            .font(.system(size: 12))
                            .foregroundColor(isTyping ? .gray : .green)
                            .animation(.easeInOut(duration: 0.3), value: isTyping)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: appear)
            
            Divider().background(Color.white.opacity(0.06))
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            if message.visible {
                                ChatBubble(text: message.text, isVexom: message.isVexom)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .id(message.id)
                            }
                        }
                        if isTyping {
                            TypingDots()
                                .transition(.opacity)
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) {
                    withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                }
                .onChange(of: isTyping) {
                    if isTyping {
                        withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                    }
                }
            }
            
            Spacer()
            
            if showContinue {
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        HStack {
                            Text("Let's do this")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "onboarding_complete")
                    }) {
                        Text("Skip intro")
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            appear = true
            pulse = true
            scheduleMessages()
        }
    }
    
    func scheduleMessages() {
        messages = introMessages.map { AIMessage(text: $0.0, isVexom: $0.1) }
        for i in introMessages.indices {
            let delay = introMessages[i].2
            let typingDelay = max(0, delay - 0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + typingDelay) {
                withAnimation { isTyping = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isTyping = false
                    messages[i].visible = true
                }
                HapticEngine.shared.playMessageAppear()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 16.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContinue = true
            }
            HapticEngine.shared.playHeartbeat()
        }
    }
}

struct TypingDots: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: animate)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .cornerRadius(18)
        .onAppear { animate = true }
    }
}

struct ChatBubble: View {
    let text: String
    let isVexom: Bool
    
    var body: some View {
        HStack {
            if !isVexom { Spacer() }
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(isVexom ? .white : .black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isVexom ? Color.white.opacity(0.08) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(isVexom ? 0.1 : 0), lineWidth: 1))
                .cornerRadius(18)
                .frame(maxWidth: screenWidth * 0.75, alignment: isVexom ? .leading : .trailing)
            if isVexom { Spacer() }
        }
    }
}

// MARK: - Phase B: Permissions Showcase
struct PermissionsPhase: View {
    let onContinue: () -> Void
    @State private var revealedCount = 0
    @State private var showContinue = false
    @State private var titleAppear = false
    
    let powers: [(String, String, String, Color)] = [
        ("calendar", "Your Calendar", "I'll know every class, meeting, and deadline", .blue),
        ("message.fill", "Your Messages", "I'll see who needs a reply and when", .green),
        ("music.note", "Your Vibe", "I'll know what you're listening to", .purple),
        ("person.2.fill", "Your Network", "I'll remember every person you meet", .orange),
        ("brain.head.profile", "Your Patterns", "I'll learn when you're most productive", .pink),
        ("bolt.fill", "Your Life", "I'll put it all together for you", .yellow),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 8) {
                Text("Here's what\nI can do.")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(titleAppear ? 1 : 0)
                    .offset(y: titleAppear ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: titleAppear)
                Text("Watch carefully.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .opacity(titleAppear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: titleAppear)
            }
            .padding(.bottom, 32)
            
            VStack(spacing: 10) {
                ForEach(Array(powers.enumerated()), id: \.offset) { index, power in
                    if index < revealedCount {
                        PowerRow(icon: power.0, title: power.1, subtitle: power.2, color: power.3)
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            if showContinue {
                Button(action: onContinue) {
                    HStack {
                        Text("I'm ready")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { titleAppear = true }
            schedulePowers()
        }
    }
    
    func schedulePowers() {
        for i in 0..<powers.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5 + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { revealedCount = i + 1 }
                HapticEngine.shared.playPowerReveal()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(powers.count) * 0.5 + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showContinue = true }
            HapticEngine.shared.playHeartbeat()
        }
    }
}

struct PowerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @State private var appear = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            .scaleEffect(appear ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.05), value: appear)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(color)
                .scaleEffect(appear ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15), value: appear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
        .cornerRadius(14)
        .onAppear { appear = true }
    }
}

// MARK: - Phase C: Setup
struct SetupPhase: View {
    @Binding var currentStep: Int
    @Binding var name: String
    @Binding var major: String
    @Binding var university: String
    @Binding var goals: [String]
    @Binding var wakeTime: String
    @Binding var sleepTime: String
    @Binding var showParticles: Bool
    let goalOptions: [(String, String)]
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    var canContinue: Bool {
        switch currentStep {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !university.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !goals.isEmpty
        default: return true
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= currentStep ? Color.white : Color.white.opacity(0.15))
                        .frame(height: 2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 20)
            
            Group {
                switch currentStep {
                case 0: NameStep(name: $name)
                case 1: UniversityStep(university: $university, major: $major)
                case 2: GoalsStep(goals: $goals, goalOptions: goalOptions)
                case 3: ScheduleStep(wakeTime: $wakeTime, sleepTime: $sleepTime)
                case 4: ReadyStep(name: name, goals: goals)
                default: NameStep(name: $name)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(currentStep)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {
                    if currentStep == 4 {
                        onComplete()
                    } else {
                        if currentStep == 3 {
                            showParticles = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showParticles = false }
                        }
                        HapticEngine.shared.playStepTransition()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentStep += 1 }
                    }
                }) {
                    HStack {
                        Text(currentStep == 4 ? "Secure my Vexom 🔒" : "Continue")
                            .font(.system(size: 16, weight: .semibold))
                        if currentStep < 4 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                }
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.4)
                
                if currentStep > 0 && currentStep < 4 {
                    Button(action: {
                        HapticEngine.shared.playMessageAppear()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentStep -= 1 }
                    }) {
                        Text("Back")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Setup Steps
struct NameStep: View {
    @Binding var name: String
    @State private var appear = false
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                TypewriterText(text: "What should\nI call you?", font: .system(size: 36, weight: .bold), color: .white)
                Text("I'll remember this forever")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: appear)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: appear)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("", text: $name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .focused($focused)
                    .placeholder(when: name.isEmpty) {
                        Text("Your name...")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                Rectangle()
                    .fill(name.isEmpty ? Color.white.opacity(0.15) : Color.white)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.3), value: name.isEmpty)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
            
            if !name.isEmpty {
                Text("Hey \(name) 👋")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear {
            appear = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
        }
    }
}

struct UniversityStep: View {
    @Binding var university: String
    @Binding var major: String
    @State private var appear = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                TypewriterText(text: "Where are\nyou studying?", font: .system(size: 36, weight: .bold), color: .white)
                Text("So I can understand your world")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.8), value: appear)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: appear)
            
            VStack(spacing: 16) {
                OnboardingField(placeholder: "University", text: $university, icon: "building.columns")
                OnboardingField(placeholder: "Major", text: $major, icon: "book")
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
            
            if university.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick select")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Indiana University", "Purdue", "Notre Dame", "Michigan", "Ohio State"], id: \.self) { uni in
                                Button(action: { university = uni }) {
                                    Text(uni)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.06))
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear { appear = true }
    }
}

struct GoalsStep: View {
    @Binding var goals: [String]
    let goalOptions: [(String, String)]
    @State private var appear = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                TypewriterText(text: "What are you\nchasing?", font: .system(size: 36, weight: .bold), color: .white)
                Text("Pick everything that applies")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.7), value: appear)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: appear)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(goalOptions.enumerated()), id: \.element.1) { index, goal in
                    let isSelected = goals.contains(goal.1)
                    Button(action: {
                        if isSelected {
                            HapticEngine.shared.playGoalDeselect()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { goals.removeAll { $0 == goal.1 } }
                        } else {
                            HapticEngine.shared.playGoalSelect()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { goals.append(goal.1) }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(goal.0).font(.system(size: 20))
                            Text(goal.1)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(isSelected ? Color.white : Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.white : Color.white.opacity(0.08), lineWidth: 1))
                        .cornerRadius(14)
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1 + Double(index) * 0.06), value: appear)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear { appear = true }
    }
}

struct ScheduleStep: View {
    @Binding var wakeTime: String
    @Binding var sleepTime: String
    @State private var appear = false
    let wakeTimes = ["5:00 AM", "6:00 AM", "7:00 AM", "8:00 AM", "9:00 AM", "10:00 AM"]
    let sleepTimes = ["10:00 PM", "11:00 PM", "12:00 AM", "1:00 AM", "2:00 AM", "3:00 AM"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                TypewriterText(text: "What's your\nschedule like?", font: .system(size: 36, weight: .bold), color: .white)
                Text("I'll work around your rhythm")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.8), value: appear)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: appear)
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("I usually wake up around")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(wakeTimes, id: \.self) { time in
                                Button(action: { HapticEngine.shared.playMessageAppear(); wakeTime = time }) {
                                    Text(time)
                                        .font(.system(size: 14, weight: wakeTime == time ? .semibold : .regular))
                                        .foregroundColor(wakeTime == time ? .black : .white.opacity(0.7))
                                        .padding(.horizontal, 16).padding(.vertical, 10)
                                        .background(wakeTime == time ? Color.white : Color.white.opacity(0.06))
                                        .cornerRadius(20)
                                        .scaleEffect(wakeTime == time ? 1.05 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: wakeTime)
                                }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("I usually sleep around")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sleepTimes, id: \.self) { time in
                                Button(action: { HapticEngine.shared.playMessageAppear(); sleepTime = time }) {
                                    Text(time)
                                        .font(.system(size: 14, weight: sleepTime == time ? .semibold : .regular))
                                        .foregroundColor(sleepTime == time ? .black : .white.opacity(0.7))
                                        .padding(.horizontal, 16).padding(.vertical, 10)
                                        .background(sleepTime == time ? Color.white : Color.white.opacity(0.06))
                                        .cornerRadius(20)
                                        .scaleEffect(sleepTime == time ? 1.05 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: sleepTime)
                                }
                            }
                        }
                    }
                }
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear { appear = true }
    }
}

struct ReadyStep: View {
    let name: String
    let goals: [String]
    @State private var appear = false
    @State private var pulse = false
    @State private var rotateRing = false
    @State private var personalMessageIndex = 0
    
    var personalMessage: String {
        if goals.contains("Land an internship") {
            return "Let's get you that internship, \(name.isEmpty ? "friend" : name)."
        } else if goals.contains("Start a company") {
            return "Future founder. I'll help you build it, \(name.isEmpty ? "friend" : name)."
        } else if goals.contains("Grow my network") {
            return "I'll help you connect with the right people, \(name.isEmpty ? "friend" : name)."
        } else if goals.contains("Ace my classes") {
            return "Dean's List incoming, \(name.isEmpty ? "friend" : name)."
        } else if goals.contains("Build side projects") {
            return "Time to ship something great, \(name.isEmpty ? "friend" : name)."
        } else {
            return "Vexom is ready to work for you, \(name.isEmpty ? "friend" : name)."
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.05 - Double(i) * 0.01), lineWidth: 1)
                        .frame(width: CGFloat(100 + i * 50), height: CGFloat(100 + i * 50))
                        .scaleEffect(appear ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.2 + Double(i) * 0.15), value: appear)
                }
                Circle()
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(rotateRing ? 360 : 0))
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: rotateRing)
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulse ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                Text("⚡")
                    .font(.system(size: 44))
                    .scaleEffect(appear ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: appear)
            }
            .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                TypewriterText(
                    text: "You're all set ⚡",
                    font: .system(size: 36, weight: .bold),
                    color: .white
                )
                .multilineTextAlignment(.center)
                
                Text(personalMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(1.4), value: appear)
                
                // Show selected goals as chips
                if !goals.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(goals.prefix(3), id: \.self) { goal in
                                Text(goal)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(1.8), value: appear)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            appear = true
            pulse = true
            rotateRing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HapticEngine.shared.playSuccess()
            }
        }
    }
}

// MARK: - Helpers
struct OnboardingField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(12)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
