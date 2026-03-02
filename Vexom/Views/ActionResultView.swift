import SwiftUI
import EventKit

struct ActionResultView: View {
    let result: IntelligenceResult
    let onDismiss: () -> Void
    
    @State private var appear = false
    @State private var saved = false
    @State private var saving = false
    @State private var editedTitle: String = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    
                    // Header
                    HStack {
                        ZStack {
                            Circle()
                                .fill(typeColor.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: typeIcon)
                                .font(.system(size: 22))
                                .foregroundColor(typeColor)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(typeLabel)
                                .font(.system(size: 13))
                                .foregroundColor(typeColor)
                            Text(confidenceText)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Content fields
                    VStack(alignment: .leading, spacing: 10) {
                        if result.type == .unknown {
                            Text(result.detail)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            // Title
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Title")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                TextField("Title", text: $editedTitle)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            
                            // Detail
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Details")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                Text(result.detail)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            
                            // Date
                            if let date = result.date {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text(dateString(date))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                            
                            // Meeting link
                            if let link = result.link {
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(.purple)
                                    Text(link)
                                        .font(.system(size: 12))
                                        .foregroundColor(.purple)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.purple.opacity(0.08))
                                .cornerRadius(12)
                            }
                            
                            // Email
                            if let email = result.email {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.green)
                                    Text(email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action buttons
                    VStack(spacing: 10) {
                        if result.type != .unknown {
                            Button(action: performAction) {
                                HStack {
                                    if saving {
                                        ProgressView().tint(.black).scaleEffect(0.8)
                                    } else if saved {
                                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                                    } else {
                                        Image(systemName: actionIcon).font(.system(size: 14))
                                    }
                                    Text(saved ? "Saved!" : actionLabel)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(saved ? Color.green : Color.white)
                                .cornerRadius(16)
                            }
                            .disabled(saving || saved)
                        }
                        
                        Button(action: sendToChat) {
                            HStack {
                                Image(systemName: "bubble.left").font(.system(size: 14))
                                Text("Ask Vexom about this").font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                        }
                        
                        Button(action: onDismiss) {
                            Text("Dismiss")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(white: 0.08))
                        .ignoresSafeArea(edges: .bottom)
                )
                .offset(y: appear ? 0 : 400)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appear)
            }
        }
        .onAppear {
            editedTitle = result.title
            appear = true
            HapticEngine.shared.playPowerReveal()
        }
    }
    
    var typeColor: Color {
        switch result.type {
        case .meeting: return .blue
        case .assignment: return .orange
        case .contact: return .green
        case .notes: return .purple
        case .unknown: return .gray
        }
    }
    
    var typeIcon: String {
        switch result.type {
        case .meeting: return "video.fill"
        case .assignment: return "doc.text.fill"
        case .contact: return "person.fill"
        case .notes: return "note.text"
        case .unknown: return "questionmark"
        }
    }
    
    var typeLabel: String {
        switch result.type {
        case .meeting: return "Meeting detected"
        case .assignment: return "Assignment detected"
        case .contact: return "Contact detected"
        case .notes: return "Notes detected"
        case .unknown: return "Not sure what this is"
        }
    }
    
    var confidenceText: String {
        let pct = Int(result.confidence * 100)
        if pct >= 90 { return "Very confident (\(pct)%)" }
        if pct >= 75 { return "Confident (\(pct)%)" }
        return "Not very sure (\(pct)%)"
    }
    
    var actionLabel: String {
        switch result.type {
        case .meeting, .assignment: return "Add to Calendar"
        case .contact: return "Save to People"
        default: return "Save"
        }
    }
    
    var actionIcon: String {
        switch result.type {
        case .meeting, .assignment: return "calendar.badge.plus"
        case .contact: return "person.badge.plus"
        default: return "square.and.arrow.down"
        }
    }
    
    func performAction() {
        saving = true
        HapticEngine.shared.playGoalSelect()
        switch result.type {
        case .meeting, .assignment: addToCalendar()
        case .contact: saveToPeople()
        default:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                saving = false
                saved = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onDismiss() }
            }
        }
    }
    
    func addToCalendar() {
        let store = EKEventStore()
        Task {
            do {
                try await store.requestFullAccessToEvents()
                let event = EKEvent(eventStore: store)
                event.title = editedTitle
                event.startDate = result.date ?? Date().addingTimeInterval(3600)
                event.endDate = event.startDate.addingTimeInterval(3600)
                event.calendar = store.defaultCalendarForNewEvents
                if let link = result.link {
                    event.notes = "Meeting Link: \(link)"
                    event.url = URL(string: link)
                }
                if result.type == .assignment {
                    event.addAlarm(EKAlarm(relativeOffset: -259200))
                }
                try store.save(event, span: .thisEvent)
                await MainActor.run {
                    saving = false
                    saved = true
                    HapticEngine.shared.playSuccess()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onDismiss() }
                }
            } catch {
                await MainActor.run { saving = false }
            }
        }
    }
    
    func saveToPeople() {
        var people = UserDefaults.standard.array(forKey: "vexom_people") as? [[String: String]] ?? []
        let person: [String: String] = [
            "name": editedTitle,
            "email": result.email ?? "",
            "company": result.company ?? "",
            "phone": result.phone ?? "",
            "metDate": ISO8601DateFormatter().string(from: Date()),
            "notes": result.detail
        ]
        people.append(person)
        UserDefaults.standard.set(people, forKey: "vexom_people")
        saving = false
        saved = true
        HapticEngine.shared.playSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onDismiss() }
    }
    
    func sendToChat() {
        UserDefaults.standard.set(result.rawText, forKey: "pending_chat_text")
        onDismiss()
    }
    
    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
