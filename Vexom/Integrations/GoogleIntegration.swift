import Foundation

class GoogleIntegration {
    
    static let shared = GoogleIntegration()
    
    private var accessToken: String? {
        return GoogleAuthManager.shared.accessToken
    }
    
    // MARK: - Gmail
    
    func getUnreadEmails(maxResults: Int = 10, completion: @escaping ([[String: String]]) -> Void) {
        guard let token = accessToken else { completion([]); return }
        
        let urlString = "https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=\(maxResults)&q=is:unread"
        guard let url = URL(string: urlString) else { completion([]); return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let messages = json["messages"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let group = DispatchGroup()
            var emails: [[String: String]] = []
            
            for message in messages.prefix(5) {
                guard let id = message["id"] as? String else { continue }
                group.enter()
                self.getEmailDetail(id: id, token: token) { detail in
                    if let detail = detail { emails.append(detail) }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) { completion(emails) }
        }.resume()
    }
    
    private func getEmailDetail(id: String, token: String, completion: @escaping ([String: String]?) -> Void) {
        let urlString = "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)?format=metadata&metadataHeaders=From&metadataHeaders=Subject"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = json["payload"] as? [String: Any],
                  let headers = payload["headers"] as? [[String: Any]] else {
                completion(nil)
                return
            }
            
            var from = ""
            var subject = ""
            for header in headers {
                let name = header["name"] as? String ?? ""
                let value = header["value"] as? String ?? ""
                if name == "From" { from = value }
                if name == "Subject" { subject = value }
            }
            
            completion(["from": from, "subject": subject, "snippet": json["snippet"] as? String ?? ""])
        }.resume()
    }
    
    // MARK: - Google Calendar
    
    func getCalendarEvents(daysAhead: Int = 7, completion: @escaping ([[String: String]]) -> Void) {
        guard let token = accessToken else { completion([]); return }
        
        let now = ISO8601DateFormatter().string(from: Date())
        let future = ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: daysAhead, to: Date())!)
        let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin=\(now)&timeMax=\(future)&singleEvents=true&orderBy=startTime&maxResults=20"
        
        guard let url = URL(string: urlString) else { completion([]); return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            
            let events = items.compactMap { item -> [String: String]? in
                guard let summary = item["summary"] as? String else { return nil }
                let start = item["start"] as? [String: Any]
                let dateStr = start?["dateTime"] as? String ?? start?["date"] as? String ?? ""
                var displayTime = dateStr
                if let date = formatter.date(from: dateStr) {
                    displayTime = displayFormatter.string(from: date)
                }
                return ["title": summary, "time": displayTime, "location": item["location"] as? String ?? ""]
            }
            
            DispatchQueue.main.async { completion(events) }
        }.resume()
    }
    
    // MARK: - Google Tasks
    
    func getTasks(completion: @escaping ([[String: String]]) -> Void) {
        guard let token = accessToken else { completion([]); return }
        
        let urlString = "https://tasks.googleapis.com/tasks/v1/lists/@default/tasks?showCompleted=false&maxResults=20"
        guard let url = URL(string: urlString) else { completion([]); return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let tasks = items.compactMap { item -> [String: String]? in
                guard let title = item["title"] as? String else { return nil }
                return ["title": title, "due": item["due"] as? String ?? "", "notes": item["notes"] as? String ?? ""]
            }
            
            DispatchQueue.main.async { completion(tasks) }
        }.resume()
    }
}
