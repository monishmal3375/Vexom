import Foundation
import Combine

class SpotifyIntegration: NSObject, ObservableObject {
    
    static let shared = SpotifyIntegration()
    
    // Paste your Spotify credentials here
    private let clientID = Secrets.spotifyClientID
    private let clientSecret = Secrets.spotifyClientSecret
    private let redirectURI = "vexom://spotify-callback"
    
    @Published var isConnected = false
    @Published var currentTrack: SpotifyTrack? = nil
    
    private var accessToken: String? = nil
    private var refreshToken: String? = nil
    
    override init() {
        super.init()
        loadTokens()
    }
    
    // MARK: - Auth
    
    func getAuthURL() -> URL? {
        let scopes = "user-read-currently-playing user-read-recently-played user-top-read"
        let encodedScopes = scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(encodedRedirect)&scope=\(encodedScopes)"
        return URL(string: urlString)
    }
    
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return
        }
        exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let credentials = "\(clientID):\(clientSecret)"
        let encoded = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            if let access = json["access_token"] as? String,
               let refresh = json["refresh_token"] as? String {
                self.accessToken = access
                self.refreshToken = refresh
                self.saveTokens()
                DispatchQueue.main.async {
                    self.isConnected = true
                }
            }
        }.resume()
    }
    
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refresh = refreshToken,
              let url = URL(string: "https://accounts.spotify.com/api/token") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let credentials = "\(clientID):\(clientSecret)"
        let encoded = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=refresh_token&refresh_token=\(refresh)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let access = json["access_token"] as? String else {
                completion(false)
                return
            }
            self.accessToken = access
            self.saveTokens()
            completion(true)
        }.resume()
    }
    
    // MARK: - API Calls
    
    func getNowPlaying(completion: @escaping (SpotifyTrack?) -> Void) {
        guard let token = accessToken else {
            completion(nil)
            return
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            // 204 means nothing playing
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // 401 means token expired
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                self.refreshAccessToken { success in
                    if success { self.getNowPlaying(completion: completion) }
                    else { completion(nil) }
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let item = json["item"] as? [String: Any] else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let track = self.parseTrack(item: item, isPlaying: json["is_playing"] as? Bool ?? false)
            DispatchQueue.main.async {
                self.currentTrack = track
                completion(track)
            }
        }.resume()
    }
    
    func getRecentlyPlayed(completion: @escaping ([SpotifyTrack]) -> Void) {
        guard let token = accessToken,
              let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played?limit=10") else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let tracks = items.compactMap { item -> SpotifyTrack? in
                guard let track = item["track"] as? [String: Any] else { return nil }
                return self.parseTrack(item: track, isPlaying: false)
            }
            
            DispatchQueue.main.async { completion(tracks) }
        }.resume()
    }
    
    func getTopTracks(completion: @escaping ([SpotifyTrack]) -> Void) {
        guard let token = accessToken,
              let url = URL(string: "https://api.spotify.com/v1/me/top/tracks?limit=10&time_range=short_term") else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let tracks = items.map { self.parseTrack(item: $0, isPlaying: false) }
            DispatchQueue.main.async { completion(tracks) }
        }.resume()
    }
    
    // MARK: - Helpers
    
    private func parseTrack(item: [String: Any], isPlaying: Bool) -> SpotifyTrack {
        let name = item["name"] as? String ?? "Unknown"
        let artists = item["artists"] as? [[String: Any]] ?? []
        let artistName = artists.first?["name"] as? String ?? "Unknown Artist"
        let album = item["album"] as? [String: Any]
        let albumName = album?["name"] as? String ?? ""
        let images = album?["images"] as? [[String: Any]] ?? []
        let imageURL = images.first?["url"] as? String ?? ""
        let durationMs = item["duration_ms"] as? Int ?? 0
        let progressMs = item["progress_ms"] as? Int ?? 0
        
        return SpotifyTrack(
            name: name,
            artist: artistName,
            album: albumName,
            imageURL: imageURL,
            isPlaying: isPlaying,
            durationMs: durationMs,
            progressMs: progressMs
        )
    }
    
    // MARK: - Persistence
    
    private func saveTokens() {
        UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")
        UserDefaults.standard.set(refreshToken, forKey: "spotify_refresh_token")
    }
    
    private func loadTokens() {
        accessToken = UserDefaults.standard.string(forKey: "spotify_access_token")
        refreshToken = UserDefaults.standard.string(forKey: "spotify_refresh_token")
        isConnected = accessToken != nil
    }
    
    func disconnect() {
        accessToken = nil
        refreshToken = nil
        isConnected = false
        currentTrack = nil
        UserDefaults.standard.removeObject(forKey: "spotify_access_token")
        UserDefaults.standard.removeObject(forKey: "spotify_refresh_token")
    }
}

struct SpotifyTrack {
    let name: String
    let artist: String
    let album: String
    let imageURL: String
    let isPlaying: Bool
    let durationMs: Int
    let progressMs: Int
    
    var formattedDuration: String {
        let seconds = durationMs / 1000
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
    
    var summary: String {
        return "\(name) by \(artist) from \(album)"
    }
}
