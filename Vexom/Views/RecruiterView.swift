import SwiftUI

struct RecruiterView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var manager = RecruiterManager.shared
    @State private var selectedTab = 0
    @State private var showAddApplication = false
    @State private var showAddContact = false
    @State private var appear = false
    @State private var isScanning = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { appState.currentView = .home }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Recruiter Mode")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        if isScanning {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 5, height: 5)
                                Text("Scanning Gmail...")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    Spacer()
                    Button(action: { scanGmail() }) {
                        Image(systemName: isScanning ? "arrow.clockwise" : "envelope.badge")
                            .foregroundColor(isScanning ? .green : .blue)
                            .frame(width: 36, height: 36)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        statsDashboard
                            .padding(.horizontal, 20)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: appear)

                        if !manager.contactsNeedingFollowUp.isEmpty {
                            followUpBanner.padding(.horizontal, 20)
                        }

                        if manager.applications.isEmpty {
                            gmailPromptCard.padding(.horizontal, 20)
                        }

                        HStack(spacing: 0) {
                            tabButton(title: "📋 Applications (\(manager.applications.count))", index: 0)
                            tabButton(title: "👥 Contacts (\(manager.contacts.count))", index: 1)
                        }
                        .padding(.horizontal, 20)

                        if selectedTab == 0 {
                            applicationsSection
                        } else {
                            contactsSection
                        }
                    }
                    .padding(.bottom, 40)
                }
            }

            if isScanning {
                scanningOverlay
            }
        }
        .onAppear {
            appear = true
        }
       
        .sheet(isPresented: $showAddApplication) {
            AddApplicationView()
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView()
        }
    }

    // MARK: - Stats Dashboard
    var statsDashboard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                bigStatCard(value: "\(manager.stats.total)", label: "Total Applied", icon: "paperplane.fill", color: .blue)
                bigStatCard(value: "\(manager.stats.interviews)", label: "Interviews", icon: "person.fill.checkmark", color: .purple)
            }
            HStack(spacing: 12) {
                bigStatCard(value: "\(manager.stats.active)", label: "In Progress", icon: "arrow.triangle.2.circlepath", color: .orange)
                bigStatCard(value: "\(manager.stats.offers)", label: "Offers", icon: "checkmark.seal.fill", color: .green)
            }
            if manager.stats.total > 0 {
                let responseRate = Int(Double(manager.stats.interviews + manager.stats.offers) / Double(manager.stats.total) * 100)
                HStack {
                    Text("Response Rate")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(responseRate)%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(responseRate > 20 ? .green : responseRate > 10 ? .orange : .red)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(responseRate > 20 ? Color.green : responseRate > 10 ? Color.orange : Color.red)
                                .frame(width: geo.size.width * CGFloat(responseRate) / 100)
                        }
                    }
                    .frame(width: 80, height: 4)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
            }
        }
    }

    func bigStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                Text(label).font(.system(size: 11)).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.15), lineWidth: 1))
        .cornerRadius(14)
        .frame(maxWidth: .infinity)
    }

    var gmailPromptCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open.fill").font(.system(size: 32)).foregroundColor(.blue)
            Text("Let Vexom scan your Gmail")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
            Text("Vexom will automatically detect job applications, interviews, and offers from your inbox")
                .font(.system(size: 13)).foregroundColor(.gray).multilineTextAlignment(.center)
            Button(action: { scanGmail() }) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                    Text("Scan Gmail Now").font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(14)
            }
            Button(action: { showAddApplication = true }) {
                Text("Add manually instead").font(.system(size: 13)).foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.2), lineWidth: 1))
        .cornerRadius(16)
    }

    var followUpBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill").foregroundColor(.orange)
            Text("\(manager.contactsNeedingFollowUp.count) contact\(manager.contactsNeedingFollowUp.count > 1 ? "s" : "") need follow-up")
                .font(.system(size: 13, weight: .medium)).foregroundColor(.white)
            Spacer()
            Text("View →").font(.system(size: 12, weight: .semibold)).foregroundColor(.orange)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        .cornerRadius(12)
        .onTapGesture { selectedTab = 1 }
    }

    var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle().stroke(Color.blue.opacity(0.2), lineWidth: 3).frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(isScanning ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isScanning)
                    Image(systemName: "envelope.fill").foregroundColor(.blue).font(.system(size: 24))
                }
                Text("Scanning Gmail...").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                Text("Finding job applications, interviews & offers")
                    .font(.system(size: 13)).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            .padding(30)
            .background(Color(white: 0.1))
            .cornerRadius(24)
            .padding(.horizontal, 40)
        }
    }

    var applicationsSection: some View {
        VStack(spacing: 10) {
            if manager.applications.isEmpty {
                VStack(spacing: 12) {
                    Text("📭").font(.system(size: 40)).padding(.top, 30)
                    Text("No applications yet").font(.system(size: 15)).foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(ApplicationStatus.allCases, id: \.self) { status in
                    let apps = manager.applications.filter { $0.status == status }
                    if !apps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                StatusBadge(status: status)
                                Text("(\(apps.count))").font(.system(size: 12)).foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            ForEach(apps) { app in
                                ApplicationCard(application: app).padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            Button(action: { showAddApplication = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                    Text("Add Application")
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    var contactsSection: some View {
        VStack(spacing: 10) {
            if manager.contacts.isEmpty {
                VStack(spacing: 12) {
                    Text("👋").font(.system(size: 40)).padding(.top, 30)
                    Text("No recruiter contacts yet").font(.system(size: 15)).foregroundColor(.gray)
                    Text("Scan a business card with Vexom camera\nor add manually")
                        .font(.system(size: 13)).foregroundColor(.gray.opacity(0.7)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(manager.contacts) { contact in
                    ContactCard(contact: contact).padding(.horizontal, 20)
                }
            }
            Button(action: { showAddContact = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                    Text("Add Contact")
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            Text(title)
                .font(.system(size: 13, weight: selectedTab == index ? .semibold : .regular))
                .foregroundColor(selectedTab == index ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedTab == index ? Color.white.opacity(0.1) : Color.clear)
                .cornerRadius(10)
        }
    }

    func scanGmail() {
        isScanning = true
        HapticEngine.shared.playGoalSelect()
        Task {
            await GmailJobScanner.shared.scanForJobs()
            await MainActor.run {
                isScanning = false
                HapticEngine.shared.playSuccess()
            }
        }
    }
}
// MARK: - Application Card
struct ApplicationCard: View {
    let application: JobApplication
    @StateObject private var manager = RecruiterManager.shared
    @State private var showEdit = false

    var statusColor: Color {
        switch application.status {
        case .interested: return .blue
        case .applied: return .orange
        case .interview: return .purple
        case .offer: return .green
        case .rejected: return .red
        case .ghosted: return .gray
        }
    }

    var body: some View {
        Button(action: { showEdit = true }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(application.company)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(application.role)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    StatusBadge(status: application.status)
                }
                HStack(spacing: 16) {
                    if let date = application.appliedDate {
                        Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    if let location = application.location {
                        Label(location, systemImage: "location")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    if let salary = application.salary {
                        Label(salary, systemImage: "dollarsign")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                }
                if let notes = application.notes {
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(2)
                }
                HStack(spacing: 4) {
                    ForEach(ApplicationStatus.allCases.filter { $0 != .ghosted }, id: \.self) { status in
                        Capsule()
                            .fill(application.status == status ? statusColor : Color.white.opacity(0.08))
                            .frame(height: 3)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(statusColor.opacity(0.2), lineWidth: 1))
            .cornerRadius(16)
        }
        .sheet(isPresented: $showEdit) {
            EditApplicationView(application: application)
        }
    }
}

// MARK: - Contact Card
struct ContactCard: View {
    let contact: RecruiterContact
    @State private var showEdit = false

    var body: some View {
        Button(action: { showEdit = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(String(contact.name.prefix(1)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(contact.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(contact.role.rawValue) @ \(contact.company)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    if let email = contact.email {
                        Text(email)
                            .font(.system(size: 11))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if contact.needsFollowUp {
                        Text("Follow up")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(6)
                    }
                    Text(contact.metDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
            .cornerRadius(16)
        }
        .sheet(isPresented: $showEdit) {
            EditContactView(contact: contact)
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ApplicationStatus
    var color: Color {
        switch status {
        case .interested: return .blue
        case .applied: return .orange
        case .interview: return .purple
        case .offer: return .green
        case .rejected: return .red
        case .ghosted: return .gray
        }
    }
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Add Application View
struct AddApplicationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = RecruiterManager.shared
    @State private var company = ""
    @State private var role = ""
    @State private var status = ApplicationStatus.interested
    @State private var location = ""
    @State private var notes = ""
    @State private var jobURL = ""
    @State private var salary = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        formField(label: "Company *", placeholder: "e.g. EY, Deloitte", text: $company)
                        formField(label: "Role *", placeholder: "e.g. Technology Consulting Intern", text: $role)
                        formField(label: "Location", placeholder: "e.g. Chicago, IL", text: $location)
                        formField(label: "Salary / Stipend", placeholder: "e.g. $25/hr", text: $salary)
                        formField(label: "Job URL", placeholder: "paste link here", text: $jobURL)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ApplicationStatus.allCases, id: \.self) { s in
                                        Button(action: { status = s }) {
                                            Text(s.rawValue)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(status == s ? .black : .white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(status == s ? Color.white : Color.white.opacity(0.08))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            TextEditor(text: $notes)
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .frame(height: 80)
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                        }
                        Button(action: save) {
                            Text("Add Application")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        .disabled(company.isEmpty || role.isEmpty)
                        .opacity(company.isEmpty || role.isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    func formField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 13)).foregroundColor(.gray)
            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .font(.system(size: 14))
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
        }
    }

    func save() {
        let app = JobApplication(
            company: company, role: role, status: status,
            appliedDate: status == .applied ? Date() : nil,
            notes: notes.isEmpty ? nil : notes,
            salary: salary.isEmpty ? nil : salary,
            location: location.isEmpty ? nil : location,
            jobURL: jobURL.isEmpty ? nil : jobURL
        )
        manager.addApplication(app)
        HapticEngine.shared.playSuccess()
        dismiss()
    }
}

// MARK: - Add Contact View
struct AddContactView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = RecruiterManager.shared
    @State private var name = ""
    @State private var company = ""
    @State private var role = ContactRole.recruiter
    @State private var email = ""
    @State private var phone = ""
    @State private var linkedin = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        formField(label: "Name *", placeholder: "e.g. Sarah Johnson", text: $name)
                        formField(label: "Company *", placeholder: "e.g. EY", text: $company)
                        formField(label: "Email", placeholder: "sarah@ey.com", text: $email)
                        formField(label: "Phone", placeholder: "+1 312 555 0100", text: $phone)
                        formField(label: "LinkedIn", placeholder: "linkedin.com/in/...", text: $linkedin)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role").font(.system(size: 13)).foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ContactRole.allCases, id: \.self) { r in
                                        Button(action: { role = r }) {
                                            Text(r.rawValue)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(role == r ? .black : .white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(role == r ? Color.white : Color.white.opacity(0.08))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.system(size: 13)).foregroundColor(.gray)
                            TextEditor(text: $notes)
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .frame(height: 80)
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                        }
                        Button(action: save) {
                            Text("Add Contact")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        .disabled(name.isEmpty || company.isEmpty)
                        .opacity(name.isEmpty || company.isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    func formField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 13)).foregroundColor(.gray)
            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .font(.system(size: 14))
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
        }
    }

    func save() {
        let contact = RecruiterContact(
            name: name, company: company, role: role,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            linkedin: linkedin.isEmpty ? nil : linkedin,
            notes: notes.isEmpty ? nil : notes,
            metDate: Date()
        )
        manager.addContact(contact)
        HapticEngine.shared.playSuccess()
        dismiss()
    }
}

// MARK: - Edit Application View
struct EditApplicationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = RecruiterManager.shared
    @State var application: JobApplication

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status").font(.system(size: 13)).foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ApplicationStatus.allCases, id: \.self) { s in
                                        Button(action: { application.status = s }) {
                                            Text(s.rawValue)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(application.status == s ? .black : .white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(application.status == s ? Color.white : Color.white.opacity(0.08))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.system(size: 13)).foregroundColor(.gray)
                            TextEditor(text: Binding(get: { application.notes ?? "" }, set: { application.notes = $0 }))
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .frame(height: 100)
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                        }
                        Button(action: {
                            manager.updateApplication(application)
                            HapticEngine.shared.playSuccess()
                            dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        Button(action: {
                            manager.deleteApplication(id: application.id)
                            dismiss()
                        }) {
                            Text("Delete Application")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("\(application.company)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Edit Contact View
struct EditContactView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = RecruiterManager.shared
    @State var contact: RecruiterContact

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 70, height: 70)
                                Text(String(contact.name.prefix(1)))
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            Text(contact.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(contact.role.rawValue) @ \(contact.company)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        if let email = contact.email { infoRow(icon: "envelope", text: email) }
                        if let phone = contact.phone { infoRow(icon: "phone", text: phone) }
                        if let linkedin = contact.linkedin { infoRow(icon: "link", text: linkedin) }
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Follow Up Needed")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                if let date = contact.followUpDate {
                                    Text("Due: \(date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: $contact.needsFollowUp).tint(.orange)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.system(size: 13)).foregroundColor(.gray)
                            TextEditor(text: Binding(get: { contact.notes ?? "" }, set: { contact.notes = $0 }))
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .frame(height: 80)
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                        }
                        Button(action: {
                            manager.updateContact(contact)
                            HapticEngine.shared.playSuccess()
                            dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        Button(action: {
                            manager.deleteContact(id: contact.id)
                            dismiss()
                        }) {
                            Text("Remove Contact")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Contact Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 20)
            Text(text).font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}
