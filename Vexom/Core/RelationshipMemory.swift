import Foundation
import Combine

struct Person: Codable, Identifiable {
    let id: UUID
    var name: String
    var contactInfo: String
    var relationship: String
    var notes: [String]
    var lastContacted: Date?
    var replyUrgency: ReplyUrgency
    var context: String
    var tags: [String]
    
    enum ReplyUrgency: String, Codable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        case none = "none"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        contactInfo: String = "",
        relationship: String = "",
        notes: [String] = [],
        lastContacted: Date? = nil,
        replyUrgency: ReplyUrgency = .none,
        context: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.contactInfo = contactInfo
        self.relationship = relationship
        self.notes = notes
        self.lastContacted = lastContacted
        self.replyUrgency = replyUrgency
        self.context = context
        self.tags = tags
    }
}

class RelationshipMemory: NSObject, ObservableObject {
    
    static let shared = RelationshipMemory()
    
    @Published var people: [Person] = []
    
    private let storageKey = "vexom_relationships"
    
    override init() {
        super.init()
        load()
    }
    
    // MARK: - CRUD
    
    func addPerson(_ person: Person) {
        people.append(person)
        save()
    }
    
    func updatePerson(_ person: Person) {
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            people[index] = person
            save()
        }
    }
    
    func deletePerson(id: UUID) {
        people.removeAll { $0.id == id }
        save()
    }
    
    func addNote(to personId: UUID, note: String) {
        if let index = people.firstIndex(where: { $0.id == personId }) {
            people[index].notes.append(note)
            people[index].lastContacted = Date()
            save()
        }
    }
    
    // MARK: - Queries
    
    func findPerson(name: String) -> Person? {
        return people.first {
            $0.name.lowercased().contains(name.lowercased())
        }
    }
    
    func getPeopleByTag(_ tag: String) -> [Person] {
        return people.filter { $0.tags.contains(tag) }
    }
    
    func getUrgentReplies() -> [Person] {
        return people.filter { $0.replyUrgency == .high || $0.replyUrgency == .medium }
    }
    
    func getNetworkingContacts() -> [Person] {
        return people.filter { $0.tags.contains("networking") || $0.relationship == "recruiter" || $0.relationship == "professional" }
    }
    
    func getPeopleNotContactedIn(days: Int) -> [Person] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return people.filter { person in
            guard let last = person.lastContacted else { return true }
            return last < cutoff
        }
    }
    
    // MARK: - Summary for Claude
    
    func getSummaryForClaude() -> String {
        if people.isEmpty {
            return "No contacts saved yet in relationship memory."
        }
        
        var summary = "Relationship Memory:\n"
        
        let urgent = getUrgentReplies()
        if !urgent.isEmpty {
            summary += "\nNEEDS REPLY:\n"
            for person in urgent {
                summary += "- \(person.name) (\(person.relationship)): \(person.context)\n"
            }
        }
        
        let networking = getNetworkingContacts()
        if !networking.isEmpty {
            summary += "\nNETWORKING CONTACTS:\n"
            for person in networking {
                let lastContact = person.lastContacted.map {
                    let days = Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0
                    return "\(days) days ago"
                } ?? "never"
                summary += "- \(person.name): last contacted \(lastContact). \(person.context)\n"
            }
        }
        
        let notContacted = getPeopleNotContactedIn(days: 14)
        if !notContacted.isEmpty {
            summary += "\nNOT CONTACTED IN 14+ DAYS:\n"
            for person in notContacted.prefix(5) {
                summary += "- \(person.name) (\(person.relationship))\n"
            }
        }
        
        return summary
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Person].self, from: data) {
            people = decoded
        }
    }
}
