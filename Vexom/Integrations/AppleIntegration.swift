import Foundation
import EventKit

class AppleIntegration {
    
    static let shared = AppleIntegration()
    private let eventStore = EKEventStore()
    
    // MARK: - Calendar
    
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestFullAccessToEvents { granted, error in
            completion(granted)
        }
    }
    
    func getUpcomingEvents(daysAhead: Int = 7) -> [[String: String]] {
        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: daysAhead, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        
        return events.map { event in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return [
                "title": event.title ?? "Untitled",
                "time": formatter.string(from: event.startDate),
                "location": event.location ?? "",
                "calendar": event.calendar.title
            ]
        }
    }
    
    // MARK: - Reminders
    
    func requestRemindersAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestFullAccessToReminders { granted, error in
            completion(granted)
        }
    }
    
    func getReminders(completion: @escaping ([[String: String]]) -> Void) {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            guard let reminders = reminders else {
                completion([])
                return
            }
            
            let incomplete = reminders
                .filter { !$0.isCompleted }
                .sorted { a, b in
                    let dateA = a.dueDateComponents?.date ?? Date.distantFuture
                    let dateB = b.dueDateComponents?.date ?? Date.distantFuture
                    return dateA < dateB
                }
                .map { reminder -> [String: String] in
                    var dict: [String: String] = [
                        "title": reminder.title ?? "Untitled",
                        "list": reminder.calendar.title
                    ]
                    if let due = reminder.dueDateComponents?.date {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d, h:mm a"
                        dict["due"] = formatter.string(from: due)
                    }
                    return dict
                }
            
            completion(incomplete)
        }
    }
}
