import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("⚡")
                            .font(.system(size: 14))
                        Text(appState.messages.first?.content.prefix(20).description ?? "Vexom")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: { appState.clearChat() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(appState.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if appState.isLoading {
                                TypingIndicatorView()
                            }
                            
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .onChange(of: appState.messages.count) {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                
                // Input bar
                HStack(spacing: 10) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.gray)
                    TextField("Reply to Vexom...", text: $inputText)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .onSubmit { sendMessage() }
                    Button(action: { sendMessage() }) {
                        Image(systemName: "arrow.up")
                            .foregroundColor(inputText.isEmpty ? .gray : .black)
                            .frame(width: 30, height: 30)
                            .background(inputText.isEmpty ? Color.white.opacity(0.1) : Color.white)
                            .clipShape(Circle())
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 8)
            }
        }
    }
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        let userMessage = Message(role: .user, content: text)
        appState.addMessage(userMessage)
        
        appState.isLoading = true
        
        AnthropicService.shared.sendMessage(
            messages: appState.messages,
            tools: ToolRegistry.shared.allTools
        ) { result in
            DispatchQueue.main.async {
                appState.isLoading = false
                switch result {
                case .success(let (text, toolCalls)):
                    var assistantMessage = Message(role: .assistant, content: text)
                    assistantMessage.toolCalls = toolCalls
                    appState.addMessage(assistantMessage)
                case .failure(let error):
                    let errorMessage = Message(role: .assistant, content: "Error: \(error.localizedDescription)")
                    appState.addMessage(errorMessage)
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(AppState())
}
