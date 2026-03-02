import SwiftUI

struct PeopleView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var memory = RelationshipMemory.shared
    @State private var showAddPerson = false
    @State private var searchText = ""
    
    var filteredPeople: [Person] {
        if searchText.isEmpty { return memory.people }
        return memory.people.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.relationship.lowercased().contains(searchText.lowercased()) ||
            $0.tags.contains(where: { $0.lowercased().contains(searchText.lowercased()) })
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
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
                    Text("People")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showAddPerson = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search people...", text: $searchText)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                if memory.people.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Spacer()
                        Text("👥")
                            .font(.system(size: 48))
                        Text("No contacts yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Add people you want Vexom\nto keep track of for you")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button(action: { showAddPerson = true }) {
                            Text("Add First Contact")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)
                        Spacer()
                    }
                } else {
                    // People list
                    ScrollView {
                        VStack(spacing: 8) {
                            
                            // Urgent replies section
                            let urgent = memory.getUrgentReplies()
                            if !urgent.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("NEEDS REPLY")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.red.opacity(0.8))
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(urgent) { person in
                                        PersonRow(person: person)
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                            
                            // All contacts
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ALL CONTACTS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                
                                ForEach(filteredPeople.filter { $0.replyUrgency == .none }) { person in                                    PersonRow(person: person)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonView()
        }
    }
}

struct PersonRow: View {
    let person: Person
    
    var urgencyColor: Color {
        switch person.replyUrgency {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        case .none: return .clear
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                Text(String(person.name.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(person.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    if person.replyUrgency != .none {
                        Circle()
                            .fill(urgencyColor)
                            .frame(width: 6, height: 6)
                    }
                }
                Text(person.relationship.isEmpty ? "Contact" : person.relationship)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                if !person.context.isEmpty {
                    Text(person.context)
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Tags
            if !person.tags.isEmpty {
                Text(person.tags.first ?? "")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(4)
            }
            
            // Last contacted
            if let last = person.lastContacted {
                let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
                Text("\(days)d")
                    .font(.system(size: 11))
                    .foregroundColor(days > 14 ? .orange : .gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

struct AddPersonView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var contactInfo = ""
    @State private var relationship = ""
    @State private var context = ""
    @State private var tags = ""
    @State private var replyUrgency = Person.ReplyUrgency.none
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Add Contact")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Save") {
                        savePerson()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        AddPersonField(title: "Name", text: $name, placeholder: "e.g. Sarah Chen")
                        AddPersonField(title: "Contact", text: $contactInfo, placeholder: "Phone, email, or @handle")
                        AddPersonField(title: "Relationship", text: $relationship, placeholder: "e.g. recruiter, friend, professor")
                        AddPersonField(title: "Context", text: $context, placeholder: "e.g. Met at Snapchat event, interested in NomadAI")
                        AddPersonField(title: "Tags", text: $tags, placeholder: "e.g. networking, iu, snapchat")
                        
                        // Reply urgency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reply Urgency")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            HStack(spacing: 8) {
                                ForEach([Person.ReplyUrgency.none, .low, .medium, .high], id: \.self) { urgency in
                                    Button(action: { replyUrgency = urgency }) {
                                        Text(urgency.rawValue.capitalized)
                                            .font(.system(size: 12))
                                            .foregroundColor(replyUrgency == urgency ? .black : .white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(replyUrgency == urgency ? Color.white : Color.white.opacity(0.08))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    func savePerson() {
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let person = Person(
            name: name,
            contactInfo: contactInfo,
            relationship: relationship,
            replyUrgency: replyUrgency,
            context: context,
            tags: tagList
        )
        RelationshipMemory.shared.addPerson(person)
    }
}

struct AddPersonField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    PeopleView()
        .environmentObject(AppState())
}
