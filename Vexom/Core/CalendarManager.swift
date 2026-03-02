import EventKit
import Foundation
import Combine
import SwiftUI

class CalendarManager: NSObject, ObservableObject {
    
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    
    @Published var authorized = false
    @Published var nextEvent: EKEvent?
    @Published var todayEvents: [EKEvent] = []
    @Published var upcomingReminders: [EKReminder] = []
    
    // MARK: - Request Access
    func requestAccess() async {
        do {
            let calendarGranted = try await eventStore.requestFullAccessToEvents()
            let remindersGranted = try await eventStore.requestFullAccessToReminders()
            
            await MainActor.run {
                self.authorized = calendarGranted && remindersGranted
            }
            
            if calendarGranted {
                await fetchTodayEvents()
            }
            if remindersGranted {
                await fetchReminders()
            }
        } catch {
            print("Calendar access error: \(error)")
        }
    }
    
    // MARK: - Fetch Today's Events
    func fetchTodayEvents() async {
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        
        await MainActor.run {
            self.todayEvents = events
            self.nextEvent = events.first
        }
        
        // Update Dynamic Island with real data
        if let next = events.first {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let timeString = timeFormatter.string(from: next.startDate)
            
            let shortTitle = (next.title ?? "Event")
            let displayTitle = shortTitle.count > 20 ? String(shortTitle.prefix(20)) + "..." : shortTitle

            await MainActor.run {
                LiveActivityManager.shared.updateActivity(
                    statusText: "Next: \(displayTitle)",
                    urgentCount: self.upcomingReminders.filter { !$0.isCompleted }.count,
                    nextEvent: displayTitle,
                    nextEventTime: timeString
                )
            }
        } else {
            await MainActor.run {
                LiveActivityManager.shared.updateActivity(
                    statusText: "You're free today ⚡",
                    urgentCount: self.upcomingReminders.filter { !$0.isCompleted }.count,
                    nextEvent: "No events",
                    nextEventTime: ""
                )
            }
        }
    }
    
    // MARK: - Fetch Reminders
    func fetchReminders() async {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let pending = (reminders ?? [])
                    .filter { !$0.isCompleted }
                    .sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
                
                Task { @MainActor in
                    self.upcomingReminders = pending
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Get Next Event String
    var nextEventSummary: String {
        guard let event = nextEvent else { return "No upcoming events" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(event.title ?? "Event") at \(formatter.string(from: event.startDate))"
    }
    
    // MARK: - Get Today Summary
    var todaySummary: String {
        if todayEvents.isEmpty && upcomingReminders.isEmpty {
            return "Nothing scheduled today"
        }
        var parts: [String] = []
        if !todayEvents.isEmpty {
            parts.append("\(todayEvents.count) event\(todayEvents.count == 1 ? "" : "s")")
        }
        if !upcomingReminders.isEmpty {
            parts.append("\(upcomingReminders.count) reminder\(upcomingReminders.count == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }
    
    // MARK: - Refresh
    func refresh() async {
        await fetchTodayEvents()
        await fetchReminders()
    }
}
