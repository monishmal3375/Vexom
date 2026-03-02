import Foundation
import Combine

enum ApplicationStatus: String, Codable, CaseIterable {
    case interested = "Interested"
    case applied = "Applied"
    case interview = "Interview"
    case offer = "Offer"
    case rejected = "Rejected"
    case ghosted = "Ghosted"
    
    var color: String {
        switch self {
        case .interested: return "blue"
        case .applied: return "orange"
        case .interview: return "purple"
        case .offer: return "green"
        case .rejected: return "red"
        case .ghosted: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .interested: return "star.fill"
        case .applied: return "paperplane.fill"
        case .interview: return "person.fill.checkmark"
        case .offer: return "checkmark.seal.fill"
        case .rejected: return "xmark.circle.fill"
        case .ghosted: return "ghost"
        }
    }
}

enum ContactRole: String, Codable, CaseIterable {
    case recruiter = "Recruiter"
    case interviewer = "Interviewer"
    case connection = "Connection"
    case hiring_manager = "Hiring Manager"
    case referral = "Referral"
}

struct RecruiterContact: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var company: String
    var role: ContactRole
    var email: String?
    var phone: String?
    var linkedin: String?
    var notes: String?
    var metDate: Date
    var lastContactDate: Date?
    var followUpDate: Date?
    var needsFollowUp: Bool = false
}

struct JobApplication: Codable, Identifiable {
    var id: String = UUID().uuidString
    var company: String
    var role: String
    var status: ApplicationStatus
    var appliedDate: Date?
    var deadlineDate: Date?
    var interviewDate: Date?
    var notes: String?
    var contacts: [String] = [] // RecruiterContact IDs
    var salary: String?
    var location: String?
    var jobURL: String?
    var lastUpdated: Date = Date()
}

class RecruiterManager: ObservableObject {
    static let shared = RecruiterManager()
    
    @Published var contacts: [RecruiterContact] = []
    @Published var applications: [JobApplication] = []
    
    init() {
        load()
    }
    
    // MARK: - Contacts
    func addContact(_ contact: RecruiterContact) {
        contacts.insert(contact, at: 0)
        save()
        scheduleFollowUp(for: contact)
    }
    
    func updateContact(_ contact: RecruiterContact) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
            save()
        }
    }
    
    func deleteContact(id: String) {
        contacts.removeAll { $0.id == id }
        save()
    }
    
    // MARK: - Applications
    func addApplication(_ app: JobApplication) {
        applications.insert(app, at: 0)
        save()
    }
    
    func updateApplication(_ app: JobApplication) {
        if let index = applications.firstIndex(where: { $0.id == app.id }) {
            applications[index] = app
            save()
        }
    }
    
    func deleteApplication(id: String) {
        applications.removeAll { $0.id == id }
        save()
    }
    
    // MARK: - Follow Up
    func scheduleFollowUp(for contact: RecruiterContact) {
        // Auto set follow up 7 days after meeting
        var updated = contact
        updated.followUpDate = Calendar.current.date(byAdding: .day, value: 7, to: contact.metDate)
        updated.needsFollowUp = true
        updateContact(updated)
    }
    
    var contactsNeedingFollowUp: [RecruiterContact] {
        let now = Date()
        return contacts.filter { contact in
            guard let followUp = contact.followUpDate else { return false }
            return followUp <= now && contact.needsFollowUp
        }
    }
    
    var activeApplications: [JobApplication] {
        applications.filter { $0.status != .rejected && $0.status != .ghosted }
    }
    
    // MARK: - Stats
    var stats: (total: Int, active: Int, interviews: Int, offers: Int) {
        let total = applications.count
        let active = applications.filter { $0.status == .applied || $0.status == .interested }.count
        let interviews = applications.filter { $0.status == .interview }.count
        let offers = applications.filter { $0.status == .offer }.count
        return (total, active, interviews, offers)
    }
    
    // MARK: - Persistence
    func save() {
        if let contactData = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(contactData, forKey: "recruiter_contacts")
        }
        if let appData = try? JSONEncoder().encode(applications) {
            UserDefaults.standard.set(appData, forKey: "job_applications")
        }
    }
    
    func load() {
        if let contactData = UserDefaults.standard.data(forKey: "recruiter_contacts"),
           let decoded = try? JSONDecoder().decode([RecruiterContact].self, from: contactData) {
            contacts = decoded
        }
        if let appData = UserDefaults.standard.data(forKey: "job_applications"),
           let decoded = try? JSONDecoder().decode([JobApplication].self, from: appData) {
            applications = decoded
        }
    }
}
