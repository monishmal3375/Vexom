# Vexom — AI-Powered Student Intelligence App

<p align="center">
  <img src="Vexom/Assets.xcassets/AppIcon.appiconset/vexom_icon_premium.png" width="120" alt="Vexom App Icon"/>
</p>

<p align="center">
  <strong>Your AI that knows everything happening in your life — automatically.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017%2B-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/Xcode-15%2B-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/AI-Claude%20Haiku-purple?style=flat-square" />
  <img src="https://img.shields.io/badge/Status-Active%20Development-green?style=flat-square" />
</p>

---

## What is Vexom?

Vexom is an iOS student assistant that connects to your real life — your calendar, Gmail, contacts, Spotify, and camera — and uses AI to surface what matters, automatically. No manual input. No forms. Just intelligence.

Built by a freshman CS student at Indiana University as a real-world project to solve real problems: tracking internship applications, transcribing lectures, scanning documents, and staying on top of a busy student schedule.

---

## Features

### Core Intelligence
- **AI Chat** — Powered by Claude, answers questions with full context about your day
- **Dynamic Island** — Live Activity showing your next calendar event and reminder count in real time
- **Home Dashboard** — Today's events, reminders, and quick action prompts

### Recruiter Mode
- **Gmail Intelligence** — Automatically scans your inbox and detects job applications, interview invites, offers, and rejections — zero manual input
- **Auto contact creation** — Extracts recruiter name and email from job emails and saves them as contacts
- **Application pipeline** — Visual status tracker: Interested → Applied → Interview → Offer
- **Response rate dashboard** — Stats showing total apps, active, interviews, and offers
- **Follow-up reminders** — Auto-schedules 7-day follow-up for every recruiter contact

### Deep iPhone Integration
- **Camera + Vision** — Scan documents, business cards, and job postings using iOS Vision Framework
- **Live Lecture Transcription** — Real-time speech-to-text for lectures using Apple Speech framework
- **Action Button** — Press iPhone Action Button → instantly opens Vexom camera from anywhere
- **Face ID** — Biometric authentication
- **Core Haptics** — Custom haptic feedback patterns throughout the app
- **Parallax Motion** — CoreMotion-powered parallax effects on home screen

### Integrations
- **Google Calendar + Gmail** — OAuth 2.0, reads events and scans inbox
- **Apple Calendar + Reminders** — EventKit integration
- **Spotify** — OAuth, shows currently playing track
- **iMessage** — Deep link bridge

---

## Environment Dependencies

| Dependency | Purpose | Required |
|---|---|---|
| Anthropic API (Claude Haiku) | AI chat, Gmail analysis, document scanning | Yes |
| Google OAuth 2.0 | Gmail + Calendar access | Yes |
| Google Sign-In SDK | Authentication flow | Yes |
| Spotify OAuth | Now playing integration | Optional |
| Apple EventKit | Calendar + Reminders | Yes |
| Apple Speech Framework | Lecture transcription | Yes |
| Apple Vision Framework | Document + card scanning | Yes |
| ActivityKit | Dynamic Island Live Activities | Yes |
| Core Haptics | Haptic feedback | Yes |
| Core Motion | Parallax effects | Yes |

---

## AI Token Usage

Vexom uses **Claude Haiku** (`claude-haiku-4-5-20251001`) for all AI features — the most cost-efficient Claude model.

| Feature | Tokens per call (approx) | Frequency |
|---|---|---|
| Gmail job email analysis | ~300 input / 150 output | Once per day, per new email |
| Chat response | ~500–2000 input / 500 output | Per user message |
| Document/card scan | ~400 input / 200 output | Per camera scan |
| Lecture summary | ~1000 input / 300 output | Per transcription session |

**Estimated daily cost (active student use):** less than $0.05/day

**Gmail scanning:** After the initial historical scan, only new unprocessed emails are analyzed. A typical daily scan with 0–5 new job emails costs less than $0.01.

---

## Build and Run Guide

### Prerequisites
- Mac with **Xcode 15+**
- iPhone running **iOS 17+** (Dynamic Island requires iPhone 14 Pro or later)
- Apple Developer account (free tier works for personal testing)
- Anthropic API key from [console.anthropic.com](https://console.anthropic.com)
- Google Cloud project with Gmail API and Calendar API enabled

### Step 1 — Clone the repo
```bash
git clone https://github.com/monishmal3375/Vexom.git
cd Vexom
```

### Step 2 — Create your Secrets file
This file is gitignored and never pushed to GitHub. You must create it locally:
```bash
cat > Vexom/Secrets.swift << 'EOF'
// Local only - gitignored
struct Secrets {
    static let anthropicAPIKey = "YOUR_ANTHROPIC_API_KEY_HERE"
}
EOF
```

### Step 3 — Configure Google OAuth
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project and enable **Gmail API** and **Google Calendar API**
3. Create OAuth credentials with iOS app type using bundle ID `com.yourname.Vexom`
4. Copy your Client ID
5. In `Vexom/Core/GoogleAuthManager.swift` replace:
```swift
let clientID = "YOUR_GOOGLE_CLIENT_ID"
```
6. In Xcode go to Target → Info → URL Types and add your reversed client ID:
`com.googleusercontent.apps.YOUR_CLIENT_ID`

### Step 4 — Configure Spotify (optional)
In `Vexom/Integrations/SpotifyIntegration.swift` replace:
```swift
let clientID = "YOUR_SPOTIFY_CLIENT_ID"
```
Get a client ID at [developer.spotify.com](https://developer.spotify.com)

### Step 5 — Open in Xcode
```bash
open Vexom.xcodeproj
```

### Step 6 — Set your team
1. Click the **Vexom** target in Xcode
2. Go to **Signing and Capabilities**
3. Select your Apple Developer team

### Step 7 — Build and run
1. Connect your iPhone via USB
2. Select your device in the scheme selector
3. Press **Cmd + R**
4. If prompted, trust the developer profile on your iPhone:
   Settings → General → VPN and Device Management → Trust

---

## Required Permissions

On first launch Vexom will request the following permissions:

| Permission | Used for |
|---|---|
| Calendar | Reading today's events for home dashboard and Dynamic Island |
| Reminders | Showing pending reminders |
| Camera | Document and business card scanning |
| Microphone | Live lecture transcription |
| Speech Recognition | Converting lecture audio to text |
| Notifications | Job application alerts from Gmail scanner |
| Motion and Fitness | Parallax effect on home screen |

---

## Missing API Key Behavior

### Missing Anthropic API Key
If `Secrets.anthropicAPIKey` is empty or invalid, the following features will silently fail:
- AI chat will not respond
- Gmail job scanner will not analyze emails (Gmail fetching still works, the Claude analysis step fails)
- Camera document scan will return no extracted text
- Lecture transcription summary will not generate

**How to spot this in Xcode console:**
```
Claude analysis error: ...
```

### Missing Google OAuth
If Google Sign-In is not configured, the Connect Google button in Settings will fail immediately. Fix this by adding your email as a Test User in Google Cloud Console under OAuth Consent Screen → Test Users.

### Missing Spotify credentials
Spotify integration will silently disable itself and the now playing feature will return no result.

---

## Project Structure
```
Vexom/
├── Core/
│   ├── AppState.swift              # Global app state and navigation
│   ├── AnthropicService.swift      # Claude API wrapper
│   ├── CalendarManager.swift       # EventKit integration
│   ├── GmailJobScanner.swift       # Gmail AI job detection engine
│   ├── GoogleAuthManager.swift     # Google OAuth
│   ├── HapticEngine.swift          # Custom haptic patterns
│   ├── IntelligenceEngine.swift    # AI analysis orchestrator
│   ├── MotionManager.swift         # CoreMotion parallax
│   ├── TranscriptionManager.swift  # Speech-to-text
│   └── VisionManager.swift         # Camera and Vision Framework
├── Views/
│   ├── HomeView.swift              # Main dashboard
│   ├── ChatView.swift              # AI chat interface
│   ├── RecruiterView.swift         # Job tracking and Gmail intelligence
│   ├── CameraView.swift            # Document scanner
│   ├── LectureView.swift           # Live transcription
│   ├── SettingsView.swift          # Integrations and preferences
│   └── PeopleView.swift            # Contacts and relationships
├── Models/
│   ├── Message.swift               # Chat message model
│   └── RecruiterModel.swift        # Job application and contact models
├── Integrations/
│   ├── GoogleIntegration.swift
│   ├── SpotifyIntegration.swift
│   ├── AppleIntegration.swift
│   └── iMessageIntegration.swift
├── VexomIsland/                    # Dynamic Island Live Activity widget
├── VexomShare/                     # Share Extension
└── Secrets.swift                   # Local only - gitignored
```

---

## Testing

### Manual Testing Checklist

**Core features:**
- [ ] App launches and shows home dashboard
- [ ] Calendar events appear correctly
- [ ] Dynamic Island shows next event
- [ ] AI chat responds to messages
- [ ] Camera opens and scans documents

**Recruiter Mode:**
- [ ] Connect Google account in Settings
- [ ] Tap envelope icon and Gmail scan runs
- [ ] Job emails detected and appear as applications
- [ ] Recruiter contacts auto-created from emails
- [ ] Status updates correctly from Applied to Interview to Offer
- [ ] Notifications fire when new applications are detected

**Action Button:**
- [ ] Set Shortcut in Settings → Action Button
- [ ] Press Action Button and Vexom opens directly to camera

### Known Limitations
- Dynamic Island Live Activity content rendering requires a paid Apple Developer account for full functionality
- Share Extension requires App Groups which needs a paid developer account
- Background Gmail scanning is iOS-controlled and not guaranteed at exact intervals
- Gmail scanner only processes emails from the last 7 days to minimize API costs

---

## Future Improvements

- **Pattern Learning Engine** — Learn daily habits and proactively surface relevant info
- **Handwriting to Flashcards** — Scan handwritten notes and auto-generate study flashcards
- **Siri Integration** — "Hey Siri, ask Vexom what's next"
- **Spotlight Search** — Surface Vexom data in iOS Spotlight
- **Canvas LMS Integration** — Auto-detect assignment deadlines
- **Stress Detection** — Use motion and usage patterns to detect high-stress periods
- **Spatial Memory Map** — 3D Metal-rendered visualization of your knowledge
- **Private AI Memory** — On-device only mode using Secure Enclave
- **TestFlight Beta** — Public beta for IU students
- **App Store Launch** — Full submission with privacy nutrition labels

---

## Built With

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) — UI framework
- [Claude API](https://www.anthropic.com/) — AI intelligence using Haiku model
- [Google Sign-In SDK](https://developers.google.com/identity/sign-in/ios) — OAuth
- [Gmail API](https://developers.google.com/gmail/api) — Inbox scanning
- [ActivityKit](https://developer.apple.com/documentation/activitykit) — Dynamic Island
- [Vision Framework](https://developer.apple.com/documentation/vision) — Document scanning
- [Speech Framework](https://developer.apple.com/documentation/speech) — Transcription
- [EventKit](https://developer.apple.com/documentation/eventkit) — Calendar and Reminders
- [Core Haptics](https://developer.apple.com/documentation/corehaptics) — Haptic feedback
- [Core Motion](https://developer.apple.com/documentation/coremotion) — Parallax effects

---

## Author

**Monish Malla**
Freshman, Computer Science — Indiana University Luddy School of Informatics, Computing, and Engineering
Dean's List, Fall 2025

[GitHub](https://github.com/monishmal3375) · [LinkedIn](https://linkedin.com/in/monishmalla)

---

*Built daily. Shipped publicly. Learning by doing.*
