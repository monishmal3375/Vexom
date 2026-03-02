import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    @State private var expandedTools: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            if message.role == .user {
                // User bubble — right aligned
                HStack {
                    Spacer()
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .frame(maxWidth: 280, alignment: .trailing)
                }
            } else {
                // Assistant — left aligned
                VStack(alignment: .leading, spacing: 8) {
                    
                    // Tool call traces
                    if !message.toolCalls.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(message.toolCalls) { tool in
                                Button(action: {
                                    if expandedTools.contains(tool.id) {
                                        expandedTools.remove(tool.id)
                                    } else {
                                        expandedTools.insert(tool.id)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: tool.icon)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Color.white.opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        
                                        Text(tool.displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Spacer()
                                        
                                        Image(systemName: expandedTools.contains(tool.id) ? "chevron.up" : "chevron.right")
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                }
                                
                                if expandedTools.contains(tool.id), let result = tool.result {
                                    Text(result)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .background(Color.black.opacity(0.4))
                                        .cornerRadius(6)
                                        .padding(.leading, 26)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    
                    // Response text
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(i) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { animating = true }
    }
}

#Preview {
    VStack {
        MessageBubbleView(message: Message(role: .user, content: "Any urgent messages?"))
        MessageBubbleView(message: Message(role: .assistant, content: "You have 2 urgent items."))
    }
    .padding()
    .background(Color.black)
}
