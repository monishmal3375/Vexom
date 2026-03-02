import Foundation
import Combine

class AppState: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var currentView: AppView = .home
    
    enum AppView {
        case onboarding
        case home
        case chat
        case settings
        case people
        case camera
        case lecture
        case recruiter
    }
    
    func clearChat() {
        messages = []
        currentView = .home
    }
    
    func addMessage(_ message: Message) {
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }
}
