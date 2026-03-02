import SwiftUI
import GoogleSignIn

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var googleAuth = GoogleAuthManager.shared
    @ObservedObject var spotifyAuth = SpotifyIntegration.shared
    @State private var anthropicKey = ""
    @State private var canvasToken = ""
    @State private var showSaved = false
    @State private var bridgeConnected = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    HStack {
                        Button(action: { appState.currentView = .home }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text("Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // API Keys
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API KEYS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 1) {
                            SettingsRow(icon: "sparkles", iconColor: .orange, title: "Anthropic API Key", value: $anthropicKey, placeholder: "sk-ant-...")
                            Divider().background(Color.white.opacity(0.06))
                            SettingsRow(icon: "book.fill", iconColor: .red, title: "Canvas Token", value: $canvasToken, placeholder: "Paste your IU Canvas token")
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Integrations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("INTEGRATIONS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 1) {
                            
                            IntegrationRow(icon: "calendar", iconColor: .blue, title: "Apple Calendar", status: "Connected")
                            Divider().background(Color.white.opacity(0.06))
                            IntegrationRow(icon: "checklist", iconColor: .orange, title: "Apple Reminders", status: "Connected")
                            Divider().background(Color.white.opacity(0.06))
                            
                            // Google
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                                    .frame(width: 28, height: 28)
                                    .background(Color.red.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text("Google (Gmail + Calendar + Tasks)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    if googleAuth.isSignedIn {
                                        googleAuth.signOut()
                                    } else {
                                        googleAuth.signIn { _ in }
                                    }
                                }) {
                                    Text(googleAuth.isSignedIn ? "Sign Out" : "Connect")
                                        .font(.system(size: 11))
                                        .foregroundColor(googleAuth.isSignedIn ? .red : .green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(googleAuth.isSignedIn ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider().background(Color.white.opacity(0.06))
                            
                            // Spotify
                            HStack(spacing: 12) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 13))
                                    .foregroundColor(.green)
                                    .frame(width: 28, height: 28)
                                    .background(Color.green.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text("Spotify")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    if spotifyAuth.isConnected {
                                        spotifyAuth.disconnect()
                                    } else {
                                        if let url = spotifyAuth.getAuthURL() {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                }) {
                                    Text(spotifyAuth.isConnected ? "Disconnect" : "Connect")
                                        .font(.system(size: 11))
                                        .foregroundColor(spotifyAuth.isConnected ? .red : .green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(spotifyAuth.isConnected ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider().background(Color.white.opacity(0.06))
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                                    .frame(width: 28, height: 28)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text("iMessage (Mac Bridge)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(bridgeConnected ? "Connected" : "Not Running")
                                    .font(.system(size: 11))
                                    .foregroundColor(bridgeConnected ? .green : .gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(bridgeConnected ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                                    .cornerRadius(6)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            Divider().background(Color.white.opacity(0.06))
                            IntegrationRow(icon: "car.fill", iconColor: .white, title: "Uber", status: "Coming Phase 4")
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Save button
                    Button(action: saveSettings) {
                        Text(showSaved ? "Saved ✓" : "Save Settings")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 4) {
                        Text("Vexom")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Phase 3 — Built by Monish")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.2))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            anthropicKey = UserDefaults.standard.string(forKey: "anthropic_key") ?? ""
            canvasToken = UserDefaults.standard.string(forKey: "canvas_token") ?? ""
            iMessageIntegration.shared.isReachable { reachable in
                DispatchQueue.main.async {
                    bridgeConnected = reachable
                }
            }
        }
        
    }
    
    func saveSettings() {
        UserDefaults.standard.set(anthropicKey, forKey: "anthropic_key")
        UserDefaults.standard.set(canvasToken, forKey: "canvas_token")
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaved = false }
    }
}
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                TextField(placeholder, text: $value)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct IntegrationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let status: String
    var isConnected: Bool { status == "Connected" }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Text(status)
                .font(.system(size: 11))
                .foregroundColor(isConnected ? .green : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isConnected ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
