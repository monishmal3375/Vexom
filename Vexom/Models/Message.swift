import Foundation

struct Message: Identifiable {
    let id = UUID()
    let role: MessageRole
    var content: String
    var toolCalls: [ToolCall] = []
    let timestamp: Date = Date()
}

enum MessageRole {
    case user
    case assistant
}

struct ToolCall: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let icon: String
    let color: String
    var result: String?
    var isExpanded: Bool = false
}
