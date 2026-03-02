import SwiftUI
import GoogleSignIn

@main
struct VexomApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        GoogleAuthManager.shared.configure()
        GoogleAuthManager.shared.restoreSession()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    // Google Sign In
                    GIDSignIn.sharedInstance.handle(url)
                    
                    guard url.scheme == "vexom" else { return }
                    
                    if url.host == "camera" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            appState.currentView = .camera
                        }
                    } else if url.host == "spotify-callback" {
                        SpotifyIntegration.shared.handleCallback(url: url)
                    } else if url.host == "action" {
                        handleActionURL(url)
                    }
                }
        }
    }
    
    func handleActionURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let textParam = components.queryItems?.first(where: { $0.name == "text" })?.value,
              let text = textParam.removingPercentEncoding else { return }
        
        Task {
            let result = await IntelligenceEngine.shared.analyze(text: text)
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .vexomActionReceived,
                    object: result
                )
            }
        }
    }
}

extension Notification.Name {
    static let vexomActionReceived = Notification.Name("vexomActionReceived")
}
