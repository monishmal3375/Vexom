import Foundation
import Combine
import GoogleSignIn

class GoogleAuthManager: NSObject, ObservableObject {
    
    static let shared = GoogleAuthManager()
    
    @Published var isSignedIn = false
    var accessToken: String? = nil
    
    func configure() {
        let clientID = "38920210148-ia633ha8smui7hkbu9cmk6qqdto8eiht.apps.googleusercontent.com"
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    func signIn(completion: @escaping (Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        let scopes = [
            "https://www.googleapis.com/auth/gmail.readonly",
            "https://www.googleapis.com/auth/calendar.readonly",
            "https://www.googleapis.com/auth/tasks.readonly"
        ]
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: scopes
        ) { result, error in
            if let error = error {
                print("Google Sign In error: \(error)")
                completion(false)
                return
            }
            self.accessToken = result?.user.accessToken.tokenString
            DispatchQueue.main.async {
                self.isSignedIn = true
            }
            if let token = self.accessToken {
                UserDefaults.standard.set(token, forKey: "google_access_token")
            }
            completion(true)
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        DispatchQueue.main.async {
            self.isSignedIn = false
        }
        accessToken = nil
        UserDefaults.standard.removeObject(forKey: "google_access_token")
    }
    
    func restoreSession() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                self.accessToken = user.accessToken.tokenString
                DispatchQueue.main.async {
                    self.isSignedIn = true
                }
            }
        }
    }
}
