import Foundation

struct ToolInfo {
    let displayName: String
    let icon: String
    let color: String
}

class ToolRegistry {
    
    static let shared = ToolRegistry()
    
    func getToolInfo(name: String) -> ToolInfo {
        switch name {
        case "get_calendar_events":
            return ToolInfo(displayName: "Calendar: Get Events", icon: "calendar", color: "blue")
        case "get_reminders":
            return ToolInfo(displayName: "Reminders: Get Tasks", icon: "checklist", color: "orange")
        case "get_canvas_assignments":
            return ToolInfo(displayName: "Canvas: Get Assignments", icon: "book", color: "red")
        case "get_gmail_unread":
            return ToolInfo(displayName: "Gmail: Get Unread", icon: "envelope", color: "red")
        case "get_google_calendar":
            return ToolInfo(displayName: "Google Calendar: Get Events", icon: "calendar", color: "blue")
        case "get_google_tasks":
            return ToolInfo(displayName: "Google Tasks: Get Tasks", icon: "checklist", color: "blue")
        case "get_spotify_now_playing":
            return ToolInfo(displayName: "Spotify: Now Playing", icon: "music.note", color: "green")
        case "get_spotify_recently_played":
            return ToolInfo(displayName: "Spotify: Recently Played", icon: "music.note", color: "green")
        case "get_imessages_unreplied":
            return ToolInfo(displayName: "iMessage: Unreplied", icon: "message.fill", color: "blue")
        case "get_imessages_recent":
            return ToolInfo(displayName: "iMessage: Recent", icon: "message.fill", color: "blue")
        default:
            return ToolInfo(displayName: name, icon: "wrench", color: "gray")
        }
    }
    
    func executeTool(name: String, input: [String: Any], completion: @escaping (String) -> Void) {
        switch name {
            
        case "get_calendar_events":
            let days = input["days_ahead"] as? Int ?? 7
            AppleIntegration.shared.requestCalendarAccess { granted in
                if granted {
                    let events = AppleIntegration.shared.getUpcomingEvents(daysAhead: days)
                    if events.isEmpty {
                        completion("No upcoming events in the next \(days) days.")
                    } else {
                        let result = events.map { "- \($0["title"] ?? "") at \($0["time"] ?? "")" }.joined(separator: "\n")
                        completion(result)
                    }
                } else {
                    completion("Calendar access denied.")
                }
            }
            
        case "get_reminders":
            AppleIntegration.shared.requestRemindersAccess { granted in
                if granted {
                    AppleIntegration.shared.getReminders { reminders in
                        if reminders.isEmpty {
                            completion("No incomplete reminders found.")
                        } else {
                            let result = reminders.prefix(10).map { r in
                                let due = r["due"].map { " (due \($0))" } ?? ""
                                return "- \(r["title"] ?? "")\(due)"
                            }.joined(separator: "\n")
                            completion(result)
                        }
                    }
                } else {
                    completion("Reminders access denied.")
                }
            }
            
        case "get_gmail_unread":
            GoogleIntegration.shared.getUnreadEmails { emails in
                if emails.isEmpty {
                    completion("No unread emails or Gmail not connected.")
                } else {
                    let result = emails.map { "- From: \($0["from"] ?? "") | \($0["subject"] ?? "")" }.joined(separator: "\n")
                    completion(result)
                }
            }
            
        case "get_google_calendar":
            GoogleIntegration.shared.getCalendarEvents { events in
                if events.isEmpty {
                    completion("No upcoming events or Google Calendar not connected.")
                } else {
                    let result = events.map { "- \($0["title"] ?? "") at \($0["time"] ?? "")" }.joined(separator: "\n")
                    completion(result)
                }
            }
            
        case "get_google_tasks":
            GoogleIntegration.shared.getTasks { tasks in
                if tasks.isEmpty {
                    completion("No tasks found or Google Tasks not connected.")
                } else {
                    let result = tasks.map { "- \($0["title"] ?? "")" }.joined(separator: "\n")
                    completion(result)
                }
            }
            
        case "get_canvas_assignments":
            completion("Canvas integration coming soon.")
            
        case "get_spotify_now_playing":
            SpotifyIntegration.shared.getNowPlaying { track in
                if let track = track {
                    let status = track.isPlaying ? "Currently playing" : "Last played"
                    completion("\(status): \(track.summary)")
                } else {
                    completion("Nothing playing on Spotify right now.")
                }
            }
            
        case "get_spotify_recently_played":
            SpotifyIntegration.shared.getRecentlyPlayed { tracks in
                if tracks.isEmpty {
                    completion("No recently played tracks or Spotify not connected.")
                } else {
                    let result = tracks.prefix(5).map { "- \($0.summary)" }.joined(separator: "\n")
                    completion(result)
                }
            }
            
        case "get_imessages_unreplied":
            iMessageIntegration.shared.getUnrepliedMessages { messages in
                if messages.isEmpty {
                    completion("No unreplied messages or Mac bridge not running.")
                } else {
                    let result = messages.map { msg in
                        "- \(msg["contact"] ?? "") said: \"\(msg["last_message"] ?? "")\" at \(msg["received_at"] ?? "")"
                    }.joined(separator: "\n")
                    completion(result)
                }
            }
            
        case "get_imessages_recent":
            iMessageIntegration.shared.getRecentMessages { messages in
                if messages.isEmpty {
                    completion("No messages found or Mac bridge not running.")
                } else {
                    let result = messages.prefix(10).map { msg in
                        let direction = msg["is_from_me"] == "true" ? "You" : msg["contact"] ?? "Them"
                        return "- \(direction): \(msg["message"] ?? "")"
                    }.joined(separator: "\n")
                    completion(result)
                }
            }
            
        default:
            completion("Tool not implemented yet.")
        }
    }
    
    var allTools: [[String: Any]] {
        return [
            [
                "name": "get_calendar_events",
                "description": "Get upcoming Apple Calendar events for Monish",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "days_ahead": ["type": "number", "description": "How many days ahead to look"]
                    ]
                ]
            ],
            [
                "name": "get_reminders",
                "description": "Get reminders and tasks from Apple Reminders",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "list_name": ["type": "string", "description": "Name of the reminders list"]
                    ]
                ]
            ],
            [
                "name": "get_gmail_unread",
                "description": "Get unread Gmail messages",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "max_results": ["type": "number", "description": "Max emails to return"]
                    ]
                ]
            ],
            [
                "name": "get_google_calendar",
                "description": "Get upcoming Google Calendar events",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "days_ahead": ["type": "number", "description": "How many days ahead to look"]
                    ]
                ]
            ],
            [
                "name": "get_google_tasks",
                "description": "Get tasks from Google Tasks",
                "input_schema": [
                    "type": "object",
                    "properties": [:] as [String: Any]
                ]
            ],
            [
                "name": "get_canvas_assignments",
                "description": "Get upcoming Canvas assignments from IU",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "days_ahead": ["type": "number", "description": "How many days ahead to look"]
                    ]
                ]
            ],
            [
                "name": "get_spotify_now_playing",
                "description": "Get currently playing Spotify track for Monish",
                "input_schema": [
                    "type": "object",
                    "properties": [:] as [String: Any]
                ]
            ],
            [
                "name": "get_spotify_recently_played",
                "description": "Get Monish's recently played Spotify tracks",
                "input_schema": [
                    "type": "object",
                    "properties": [:] as [String: Any]
                ]
            ],
            [
                "name": "get_imessages_unreplied",
                "description": "Get iMessages that Monish hasn't replied to yet",
                "input_schema": [
                    "type": "object",
                    "properties": [:] as [String: Any]
                ]
            ],
            [
                "name": "get_imessages_recent",
                "description": "Get Monish's recent iMessages",
                "input_schema": [
                    "type": "object",
                    "properties": [:] as [String: Any]
                ]
            ]
        ]
    }
}
