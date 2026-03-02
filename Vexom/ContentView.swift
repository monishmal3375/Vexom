import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch appState.currentView {
            case .onboarding:
                OnboardingView()
                    .environmentObject(appState)
                    .transition(.opacity)
            case .home:
                HomeView()
                    .environmentObject(appState)
                    .transition(.opacity)
            case .chat:
                ChatView()
                    .environmentObject(appState)
                    .transition(.opacity)
            case .settings:
                SettingsView()
                    .environmentObject(appState)
                    .transition(.opacity)
            case .people:
                PeopleView()
                    .environmentObject(appState)
                    .transition(.opacity)
            case .camera:
                CameraView()
            case .lecture:
                LectureView()
            case .recruiter:
                RecruiterView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.currentView)
        .onAppear {
            UserDefaults.standard.removeObject(forKey: "onboarding_complete")
        let onboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
            if !onboardingComplete {
                appState.currentView = .onboarding
            }
        }
    }
}

#Preview {
    ContentView()
}
