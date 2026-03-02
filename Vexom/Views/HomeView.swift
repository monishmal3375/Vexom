import SwiftUI
import EventKit
import Combine
import ActivityKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var calendar = CalendarManager.shared
    @State private var inputText = ""
    @State private var appear = false
    @State private var currentTime = Date()
    @State private var showActionResult = false
    @State private var pendingResult: IntelligenceResult? = nil
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = UserDefaults.standard.string(forKey: "user_name") ?? ""
        if hour < 12 { return "Good morning\(name.isEmpty ? "" : ", \(name)") ☀️" }
        else if hour < 17 { return "Good afternoon\(name.isEmpty ? "" : ", \(name)") ⚡" }
        else { return "Good evening\(name.isEmpty ? "" : ", \(name)") 🌙" }
    }
    
    let quickActions = [
        ("Any urgent messages?", "envelope.fill"),
        ("Plan my day", "calendar"),
        ("Canvas assignments?", "book.fill"),
        ("What am I listening to?", "music.note")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { appState.currentView = .settings }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    Button(action: { appState.currentView = .camera }) {
                        Image(systemName: "camera")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    Button(action: { appState.currentView = .recruiter }) {
                        Image(systemName: "briefcase")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    Button(action: { appState.currentView = .people }) {
                        Image(systemName: "person.2")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    Button(action: { appState.currentView = .lecture }) {
                        Image(systemName: "mic")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button(action: { appState.clearChat() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // Mascot + greeting
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 80, height: 80)
                                Text("⚡")
                                    .font(.system(size: 40))
                            }
                            Text(greeting)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text(calendar.todaySummary)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: appear)
                        
                        // Today's events card
                        if !calendar.todayEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 13))
                                    Text("Today")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(calendar.todayEvents.count) events")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                ForEach(calendar.todayEvents.prefix(3), id: \.eventIdentifier) { event in
                                    EventRow(event: event)
                                }
                                if calendar.todayEvents.count > 3 {
                                    Text("+\(calendar.todayEvents.count - 3) more")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
                        }
                        
                        // Reminders card
                        if !calendar.upcomingReminders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checklist")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 13))
                                    Text("Reminders")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(calendar.upcomingReminders.count) pending")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                ForEach(calendar.upcomingReminders.prefix(3), id: \.calendarItemIdentifier) { reminder in
                                    ReminderRow(reminder: reminder)
                                }
                                if calendar.upcomingReminders.count > 3 {
                                    Text("+\(calendar.upcomingReminders.count - 3) more")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
                        }
                        
                        // No data state
                        if calendar.todayEvents.isEmpty && calendar.upcomingReminders.isEmpty && calendar.authorized {
                            VStack(spacing: 8) {
                                Text("🎉").font(.system(size: 32))
                                Text("You're all clear today")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                Text("No events or reminders")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(20)
                            .opacity(appear ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
                        }
                        
                        // Quick actions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ask Vexom")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(quickActions, id: \.0) { action in
                                    Button(action: { sendMessage(action.0) }) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Image(systemName: action.1)
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.system(size: 14))
                                            Text(action.0)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                                .multilineTextAlignment(.leading)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Input bar
                HStack(spacing: 10) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.gray)
                    TextField("Ask Vexom anything...", text: $inputText)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .onSubmit { sendMessage(inputText) }
                    Button(action: { sendMessage(inputText) }) {
                        Image(systemName: "arrow.up")
                            .foregroundColor(inputText.isEmpty ? .gray : .black)
                            .frame(width: 30, height: 30)
                            .background(inputText.isEmpty ? Color.white.opacity(0.1) : Color.white)
                            .clipShape(Circle())
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Action Result Overlay
            if showActionResult, let result = pendingResult {
                ActionResultView(result: result) {
                    showActionResult = false
                    pendingResult = nil
                }
                .zIndex(999)
            }
        }
        .onAppear {
            appear = true
            
            if let pendingText = UserDefaults.standard.string(forKey: "vexom_pending_action"),
               !pendingText.isEmpty {
                UserDefaults.standard.removeObject(forKey: "vexom_pending_action")
                Task {
                    let result = await IntelligenceEngine.shared.analyze(text: pendingText)
                    await MainActor.run {
                        pendingResult = result
                        showActionResult = true
                    }
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .vexomActionReceived,
                object: nil,
                queue: .main
            ) { notification in
                if let result = notification.object as? IntelligenceResult {
                    pendingResult = result
                    showActionResult = true
                }
            }
            
            Task {
                for activity in Activity<VexomActivityAttributes>.activities {
                    await activity.end(dismissalPolicy: .immediate)
                }
                await CalendarManager.shared.requestAccess()
                await MainActor.run {
                    let nextEvent = CalendarManager.shared.nextEvent
                    let reminderCount = CalendarManager.shared.upcomingReminders.count
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    let eventTitle: String
                    let eventTime: String
                    let statusText: String
                    if let event = nextEvent {
                        let short = event.title ?? "Event"
                        let display = short.count > 20 ? String(short.prefix(20)) + "..." : short
                        eventTitle = display
                        eventTime = timeFormatter.string(from: event.startDate)
                        statusText = "Next: \(display)"
                    } else {
                        eventTitle = "No events"
                        eventTime = ""
                        statusText = "You're free today ⚡"
                    }
                    print("Starting Live Activity — status: \(statusText), event: \(eventTitle), reminders: \(reminderCount)")
                    LiveActivityManager.shared.startActivity(
                        statusText: statusText,
                        urgentCount: reminderCount,
                        nextEvent: eventTitle,
                        nextEventTime: eventTime
                    )
                }
            }
        }
        .task {
            guard GoogleAuthManager.shared.isSignedIn else { return }
            while true {
                try? await Task.sleep(nanoseconds: 24 * 60 * 60 * 1_000_000_000)
                await GmailJobScanner.shared.scanForJobs()
            }
        }        .onReceive(timer) { _ in
            Task { await CalendarManager.shared.refresh() }
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        appState.currentView = .chat
        let userMessage = Message(role: .user, content: text)
        appState.addMessage(userMessage)
        inputText = ""
    }
}

// MARK: - Event Row
struct EventRow: View {
    let event: EKEvent
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(event.calendar.cgColor))
                .frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Event")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(eventTimeString)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    var eventTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if event.isAllDay { return "All day" }
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }
}

// MARK: - Reminder Row
struct ReminderRow: View {
    let reminder: EKReminder
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle")
                .font(.system(size: 16))
                .foregroundColor(.orange.opacity(0.7))
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title ?? "Reminder")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                if let due = reminder.dueDateComponents?.date {
                    Text(dueDateString(due))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
    }
    func dueDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
