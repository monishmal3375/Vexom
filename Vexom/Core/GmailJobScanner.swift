import Foundation
import UserNotifications

class GmailJobScanner {
    static let shared = GmailJobScanner()
    
    private let claudeApiKey = "YOUR_ANTHROPIC_API_KEY"
    
    func scanForJobs() async {
        guard let token = await getValidToken() else {
            print("No Gmail access token")
            return
        }
        
        // Only 2 strict queries — minimal cost
        let queries = [
            "subject:(application OR interview OR offer OR internship) newer_than:7d",
            "from:(indeed.com OR linkedin.com OR ziprecruiter.com OR glassdoor.com OR handshake.com OR greenhouse.io OR lever.co OR myworkdayjobs.com) newer_than:7d"
        ]
        
        var allMessageIds: [String] = []
        for query in queries {
            let ids = await fetchMessageIds(token: token, query: query)
            allMessageIds.append(contentsOf: ids)
        }
        
        let uniqueIds = Array(Set(allMessageIds)).prefix(10)
        
        for id in uniqueIds {
            if let email = await fetchEmailContent(token: token, messageId: id) {
                await analyzeAndSave(email: email)
            }
        }
    }
    
    func getValidToken() async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                if let token = GoogleAuthManager.shared.accessToken {
                    continuation.resume(returning: token)
                } else {
                    GoogleAuthManager.shared.restoreSession()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        continuation.resume(returning: GoogleAuthManager.shared.accessToken)
                    }
                }
            }
        }
    }
    
    func fetchMessageIds(token: String, query: String) async -> [String] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=\(encoded)&maxResults=10") else { return [] }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let messages = json?["messages"] as? [[String: Any]] ?? []
            return messages.compactMap { $0["id"] as? String }
        } catch {
            return []
        }
    }
    
    func fetchEmailContent(token: String, messageId: String) async -> EmailContent? {
        guard let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageId)?format=full") else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            let headers = (json?["payload"] as? [String: Any])?["headers"] as? [[String: Any]] ?? []
            let subject = headers.first(where: { $0["name"] as? String == "Subject" })?["value"] as? String ?? ""
            let from = headers.first(where: { $0["name"] as? String == "From" })?["value"] as? String ?? ""
            let date = headers.first(where: { $0["name"] as? String == "Date" })?["value"] as? String ?? ""
            let body = extractBody(from: json?["payload"] as? [String: Any] ?? [:])
            
            return EmailContent(id: messageId, subject: subject, from: from, date: date, body: body)
        } catch {
            return nil
        }
    }
    
    func extractBody(from payload: [String: Any]) -> String {
        if let body = payload["body"] as? [String: Any],
           let data = body["data"] as? String {
            return decodeBase64(data)
        }
        if let parts = payload["parts"] as? [[String: Any]] {
            for part in parts {
                let mimeType = part["mimeType"] as? String ?? ""
                if mimeType == "text/plain" || mimeType == "text/html" {
                    if let body = part["body"] as? [String: Any],
                       let data = body["data"] as? String {
                        return decodeBase64(data)
                    }
                }
                if let subParts = part["parts"] as? [[String: Any]] {
                    for subPart in subParts {
                        if let body = subPart["body"] as? [String: Any],
                           let data = body["data"] as? String {
                            return decodeBase64(data)
                        }
                    }
                }
            }
        }
        return ""
    }
    
    func decodeBase64(_ string: String) -> String {
        let base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func analyzeAndSave(email: EmailContent) async {
        let processed = UserDefaults.standard.stringArray(forKey: "processed_email_ids") ?? []
        if processed.contains(email.id) { return }
        
        guard let result = await analyzeWithClaude(email: email) else { return }
        
        await MainActor.run {
            let existing = RecruiterManager.shared.applications.first(where: {
                $0.company.lowercased() == result.company.lowercased()
            })
            
            if var app = existing {
                if app.status != result.status {
                    app.status = result.status
                    app.lastUpdated = Date()
                    if result.salary != nil && app.salary == nil { app.salary = result.salary }
                    if result.location != nil && app.location == nil { app.location = result.location }
                    if let newNotes = result.notes {
                        app.notes = (app.notes ?? "") + "\n" + newNotes
                    }
                    RecruiterManager.shared.updateApplication(app)
                    sendNotification(title: "📋 \(result.company) Updated", body: "Status changed to \(result.status.rawValue)")
                }
                if let contactName = result.contactName, let contactEmail = result.contactEmail {
                    let existingContact = RecruiterManager.shared.contacts.first(where: {
                        $0.email?.lowercased() == contactEmail.lowercased()
                    })
                    if existingContact == nil {
                        let contact = RecruiterContact(
                            name: contactName, company: result.company,
                            role: .recruiter, email: contactEmail, metDate: Date()
                        )
                        RecruiterManager.shared.addContact(contact)
                    }
                }
            } else if result.company != "Unknown" && result.company != "Not a job email" {
                var newApp = JobApplication(
                    company: result.company, role: result.role, status: result.status,
                    appliedDate: result.status == .applied ? Date() : nil,
                    notes: result.notes, salary: result.salary, location: result.location
                )
                if result.status == .interview { newApp.interviewDate = Date() }
                RecruiterManager.shared.addApplication(newApp)
                sendNotification(title: "✅ \(result.company) Detected", body: "\(result.role) — \(result.status.rawValue)")
                
                if let contactName = result.contactName, let contactEmail = result.contactEmail {
                    let contact = RecruiterContact(
                        name: contactName, company: result.company,
                        role: .recruiter, email: contactEmail, metDate: Date()
                    )
                    RecruiterManager.shared.addContact(contact)
                }
            }
            
            var updatedProcessed = processed
            updatedProcessed.append(email.id)
            UserDefaults.standard.set(updatedProcessed, forKey: "processed_email_ids")
        }
    }
    
    func analyzeWithClaude(email: EmailContent) async -> JobEmailResult? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }
        
        let prompt = """
        Is this a job/internship related email? Extract info if yes.
        Subject: \(email.subject)
        From: \(email.from)
        Body: \(String(email.body.prefix(500)))
        
        Status: "interested" "applied" "interview" "offer" "rejected" "not_job"
        
        JSON only:
        {"isJob":true,"company":"name","role":"title","status":"applied","salary":null,"location":null,"notes":"one line","contactName":null,"contactEmail":null}
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(claudeApiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 150,
            "messages": [["role": "user", "content": prompt]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            let jsonText = response.content.first?.text ?? ""
            
            let cleaned = jsonText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let jsonData = cleaned.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let isJob = json["isJob"] as? Bool, isJob,
                  let statusStr = json["status"] as? String,
                  statusStr != "not_job" else { return nil }
            
            let status: ApplicationStatus = {
                switch statusStr {
                case "interested": return .interested
                case "interview": return .interview
                case "offer": return .offer
                case "rejected": return .rejected
                default: return .applied
                }
            }()
            
            return JobEmailResult(
                company: json["company"] as? String ?? "Unknown",
                role: json["role"] as? String ?? "Unknown Role",
                status: status,
                salary: json["salary"] as? String,
                location: json["location"] as? String,
                notes: json["notes"] as? String,
                contactName: json["contactName"] as? String,
                contactEmail: json["contactEmail"] as? String
            )
        } catch {
            print("Claude analysis error: \(error)")
            return nil
        }
    }
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

struct EmailContent {
    let id: String
    let subject: String
    let from: String
    let date: String
    let body: String
}

struct JobEmailResult {
    let company: String
    let role: String
    let status: ApplicationStatus
    let salary: String?
    let location: String?
    let notes: String?
    let contactName: String?
    let contactEmail: String?
}
