import ActivityKit
import Foundation

class LiveActivityManager {
    
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<VexomActivityAttributes>?
    
    // Kill everything and start fresh
    func restartActivity(statusText: String, urgentCount: Int, nextEvent: String, nextEventTime: String) {
        Task {
            // Kill ALL existing activities
            for activity in Activity<VexomActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            currentActivity = nil
            
            // Wait for them to die
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Start fresh
            await MainActor.run {
                self.startActivity(statusText: statusText, urgentCount: urgentCount, nextEvent: nextEvent, nextEventTime: nextEventTime)
            }
        }
    }
    
    func startActivity(statusText: String, urgentCount: Int, nextEvent: String, nextEventTime: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // removed the guard currentActivity == nil
        
        let attributes = VexomActivityAttributes(
            userName: UserDefaults.standard.string(forKey: "user_name") ?? "Friend"
        )
        
        let contentState = VexomActivityAttributes.ContentState(
            statusText: statusText,
            statusIcon: "bolt.fill",
            urgentCount: urgentCount,
            nextEvent: nextEvent,
            nextEventTime: nextEventTime,
            isActive: true
        )
        
        let content = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        do {
            currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(statusText: String, urgentCount: Int, nextEvent: String, nextEventTime: String) {
        guard let activity = currentActivity else { return }
        
        let contentState = VexomActivityAttributes.ContentState(
            statusText: statusText,
            statusIcon: "bolt.fill",
            urgentCount: urgentCount,
            nextEvent: nextEvent,
            nextEventTime: nextEventTime,
            isActive: true
        )
        
        let content = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        Task {
            await activity.update(content)
        }
    }
    
    func stopAll() {
        Task {
            for activity in Activity<VexomActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
    }
}
