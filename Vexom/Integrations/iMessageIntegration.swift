import Foundation

class iMessageIntegration {
    
    static let shared = iMessageIntegration()
    
    // Replace with your Mac's IP address
    private let bridgeURL = "http://127.0.0.1:5001"
    func isReachable(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(bridgeURL)/ping") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = data, error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
    
    func getUnrepliedMessages(completion: @escaping ([[String: String]]) -> Void) {
        guard let url = URL(string: "\(bridgeURL)/messages/unreplied") else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let unreplied = json["unreplied"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let messages = unreplied.map { msg -> [String: String] in
                [
                    "contact": msg["contact"] as? String ?? "",
                    "last_message": msg["last_message"] as? String ?? "",
                    "received_at": msg["received_at"] as? String ?? ""
                ]
            }
            
            DispatchQueue.main.async {
                completion(messages)
            }
        }.resume()
    }
    
    func getRecentMessages(completion: @escaping ([[String: String]]) -> Void) {
        guard let url = URL(string: "\(bridgeURL)/messages/recent") else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let messages = json["messages"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let result = messages.map { msg -> [String: String] in
                [
                    "contact": msg["contact"] as? String ?? "",
                    "message": msg["message"] as? String ?? "",
                    "is_from_me": (msg["is_from_me"] as? Bool ?? false) ? "true" : "false",
                    "sent_at": msg["sent_at"] as? String ?? ""
                ]
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }
    
    func getConversation(contact: String, completion: @escaping ([[String: String]]) -> Void) {
        let encoded = contact.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? contact
        guard let url = URL(string: "\(bridgeURL)/messages/conversation/\(encoded)") else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let messages = json["messages"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let result = messages.map { msg -> [String: String] in
                [
                    "text": msg["text"] as? String ?? "",
                    "is_from_me": (msg["is_from_me"] as? Bool ?? false) ? "true" : "false",
                    "sent_at": msg["sent_at"] as? String ?? ""
                ]
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }
}
