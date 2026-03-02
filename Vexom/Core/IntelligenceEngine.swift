import Foundation

enum IntelligenceType {
    case meeting
    case assignment
    case contact
    case notes
    case unknown
}

struct IntelligenceResult {
    let type: IntelligenceType
    let confidence: Double
    let title: String
    let detail: String
    let date: Date?
    let link: String?
    let email: String?
    let phone: String?
    let company: String?
    let rawText: String
}

class IntelligenceEngine {
    
    static let shared = IntelligenceEngine()
    
    private let apiKey = "YOUR_ANTHROPIC_API_KEY"
    
    func analyze(text: String) async -> IntelligenceResult {
        let localType = quickDetect(text: text)
        return await analyzeWithClaude(text: text, hint: localType)
    }
    
    func quickDetect(text: String) -> IntelligenceType {
        let lower = text.lowercased()
        let meetingKeywords = ["zoom.us", "teams.microsoft", "meet.google", "meeting", "call", "interview", "webex", "invited", "join us", "conference", "meeting id", "passcode", "password"]
        if meetingKeywords.contains(where: { lower.contains($0) }) { return .meeting }
        let assignmentKeywords = ["due", "deadline", "submit", "assignment", "homework", "exam", "quiz", "points", "grade"]
        if assignmentKeywords.contains(where: { lower.contains($0) }) { return .assignment }
        let hasEmail = lower.range(of: "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}", options: .regularExpression) != nil
        let hasPhone = lower.range(of: "[0-9]{3}[-.]?[0-9]{3}[-.]?[0-9]{4}", options: .regularExpression) != nil
        let contactKeywords = ["linkedin", "recruiter", "manager", "director", "engineer", "founder", "ceo"]
        if hasEmail || hasPhone || contactKeywords.contains(where: { lower.contains($0) }) { return .contact }
        return .unknown
    }
    
    func analyzeWithClaude(text: String, hint: IntelligenceType) async -> IntelligenceResult {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return fallbackResult(text: text, type: hint)
        }
        
        let prompt = """
        You are an AI assistant that analyzes text and extracts structured information. Analyze the following text carefully.
        
        Text to analyze:
        \(text)
        
        Determine what type this is and extract all relevant information:
        - "meeting": contains meeting link (zoom, teams, google meet, webex), meeting ID, passcode, or invitation to join a call
        - "assignment": contains due date, deadline, homework, exam, or task to complete
        - "contact": contains person name with email, phone number, or company
        - "notes": general notes, study material, or informational text
        - "unknown": cannot clearly determine
        
        Important rules:
        - If text contains zoom.us (any subdomain), teams.microsoft.com, or meet.google.com it is ALWAYS a meeting
        - If text contains "Meeting ID" or "Password" or "Passcode" it is ALWAYS a meeting
        - Extract the full meeting URL including any subdomain
        - Set confidence to 0.95 if you are very sure, 0.80 if fairly sure, 0.60 if unsure
        - Only set isJunk to true for obvious promotional/marketing emails
        
        Respond ONLY with this exact JSON, no other text:
        {
          "type": "meeting",
          "confidence": 0.95,
          "title": "Zoom Meeting",
          "detail": "one line summary of what this is",
          "date": null,
          "link": "full meeting URL or null",
          "email": "email address or null",
          "phone": "phone number or null",
          "company": "company name or null",
          "isJunk": false,
          "junkReason": null
        }
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 500,
            "messages": [["role": "user", "content": prompt]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("API Response: \(String(data: data, encoding: .utf8) ?? "nil")")
            let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            let jsonText = response.content.first?.text ?? ""
            print("Claude JSON: \(jsonText)")
            return parseClaudeResponse(jsonText: jsonText, originalText: text)
        } catch {
            print("API Error: \(error)")
            return fallbackResult(text: text, type: hint)
        }
    }
    
    func parseClaudeResponse(jsonText: String, originalText: String) -> IntelligenceResult {
        // Clean up JSON in case Claude adds markdown
        let cleaned = jsonText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("JSON parse failed for: \(jsonText)")
            return fallbackResult(text: originalText, type: .unknown)
        }
        
        if let isJunk = json["isJunk"] as? Bool, isJunk {
            return IntelligenceResult(
                type: .unknown, confidence: 0,
                title: "Looks like junk",
                detail: json["junkReason"] as? String ?? "Promotional content",
                date: nil, link: nil, email: nil, phone: nil, company: nil,
                rawText: originalText
            )
        }
        
        let typeString = json["type"] as? String ?? "unknown"
        let type: IntelligenceType = {
            switch typeString {
            case "meeting": return .meeting
            case "assignment": return .assignment
            case "contact": return .contact
            case "notes": return .notes
            default: return .unknown
            }
        }()
        
        var date: Date? = nil
        if let dateString = json["date"] as? String {
            date = ISO8601DateFormatter().date(from: dateString)
        }
        
        return IntelligenceResult(
            type: type,
            confidence: json["confidence"] as? Double ?? 0,
            title: json["title"] as? String ?? "Unknown",
            detail: json["detail"] as? String ?? "",
            date: date,
            link: json["link"] as? String,
            email: json["email"] as? String,
            phone: json["phone"] as? String,
            company: json["company"] as? String,
            rawText: originalText
        )
    }
    
    func fallbackResult(text: String, type: IntelligenceType) -> IntelligenceResult {
        return IntelligenceResult(
            type: type, confidence: 0.5,
            title: "Review this",
            detail: "Vexom found something — tap to review",
            date: nil, link: nil, email: nil, phone: nil, company: nil,
            rawText: text
        )
    }
}

struct AnthropicResponse: Codable {
    let content: [ContentBlock]
    struct ContentBlock: Codable {
        let text: String
    }
}
