import Foundation

class AnthropicService {
    
    static let shared = AnthropicService()
    
    private let apiKey = "YOUR_ANTHROPIC_API_KEY"
    private let apiURL = "https://api.anthropic.com/v1/messages"
    
    private let systemPrompt = """
    You are Vexom, a personal AI assistant built specifically for Monish, \
    an ambitious CS freshman at Indiana University's Luddy School. \
    You have access to his calendar, reminders, email, canvas assignments, and more.
    You are proactive, smart, and always tell him exactly what matters right now.
    You remember patterns — if he procrastinates assignments, you warn him early.
    You track his relationships and networking contacts.
    Be concise, direct, and personal. You know him well.
    Always specify the source (Calendar/Reminders/Gmail/Canvas) for each item.
    """
    
    func sendMessage(
        messages: [Message],
        tools: [[String: Any]],
        completion: @escaping (Result<(String, [ToolCall]), Error>) -> Void
    ) {
        callAPI(messages: messages, tools: tools) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let (text, toolCalls, rawContent, stopReason)):
                if stopReason == "tool_use" && !toolCalls.isEmpty {
                    // Execute all tool calls
                    let group = DispatchGroup()
                    var executedTools = toolCalls
                    
                    for (index, tool) in toolCalls.enumerated() {
                        group.enter()
                        ToolRegistry.shared.executeTool(
                            name: tool.name,
                            input: [:]
                        ) { result in
                            executedTools[index] = ToolCall(
                                name: tool.name,
                                displayName: tool.displayName,
                                icon: tool.icon,
                                color: tool.color,
                                result: result
                            )
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        // Send tool results back to Claude
                        let updatedMessages = messages
                        
                        // Add assistant's tool use message
                        let assistantMsg: [String: Any] = [
                            "role": "assistant",
                            "content": rawContent
                        ]
                        
                        // Build tool results
                        let toolResults: [[String: Any]] = executedTools.map { tool in
                            [
                                "type": "tool_result",
                                "tool_use_id": rawContent.first(where: {
                                    ($0["name"] as? String) == tool.name
                                })?["id"] as? String ?? "",
                                "content": tool.result ?? "No result"
                            ]
                        }
                        
                        let toolResultMsg: [String: Any] = [
                            "role": "user",
                            "content": toolResults
                        ]
                        
                        // Build final API messages
                        var apiMessages = updatedMessages.map { msg -> [String: Any] in
                            [
                                "role": msg.role == .user ? "user" : "assistant",
                                "content": msg.content
                            ]
                        }
                        apiMessages.append(assistantMsg)
                        apiMessages.append(toolResultMsg)
                        
                        // Call API again with tool results
                        self.callAPIRaw(messages: apiMessages, tools: tools) { finalResult in
                            switch finalResult {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success(let finalText):
                                completion(.success((finalText, executedTools)))
                            }
                        }
                    }
                } else {
                    completion(.success((text, toolCalls)))
                }
            }
        }
    }
    
    private func callAPI(
        messages: [Message],
        tools: [[String: Any]],
        completion: @escaping (Result<(String, [ToolCall], [[String: Any]], String), Error>) -> Void
    ) {
        guard let url = URL(string: apiURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let apiMessages = messages.map { msg -> [String: Any] in
            ["role": msg.role == .user ? "user" : "assistant", "content": msg.content]
        }
        
        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": systemPrompt,
            "tools": tools,
            "messages": apiMessages
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let content = json?["content"] as? [[String: Any]] ?? []
                let stopReason = json?["stop_reason"] as? String ?? ""
                
                var textResponse = ""
                var toolCalls: [ToolCall] = []
                
                for block in content {
                    let type = block["type"] as? String
                    if type == "text" {
                        textResponse = block["text"] as? String ?? ""
                    } else if type == "tool_use" {
                        let name = block["name"] as? String ?? ""
                        let info = ToolRegistry.shared.getToolInfo(name: name)
                        toolCalls.append(ToolCall(
                            name: name,
                            displayName: info.displayName,
                            icon: info.icon,
                            color: info.color
                        ))
                    }
                }
                completion(.success((textResponse, toolCalls, content, stopReason)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func callAPIRaw(
        messages: [[String: Any]],
        tools: [[String: Any]],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: apiURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": systemPrompt,
            "tools": tools,
            "messages": messages
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let content = json?["content"] as? [[String: Any]] ?? []
                let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String ?? ""
                completion(.success(text))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
