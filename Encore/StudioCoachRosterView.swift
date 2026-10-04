import SwiftUI
import Foundation

// Helper struct for navigationDestination
struct IdentifiableRoutineItem: Identifiable, Hashable {
    let student: DancerConnection
    let routine: DBRoutineRow
    
    var id: UUID { routine.id }
    
    static func == (lhs: IdentifiableRoutineItem, rhs: IdentifiableRoutineItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Coach Roster & Students Management View (Studio Tier)
struct StudioCoachRosterView: View {
    @ObservedObject private var connectionManager = ConnectionManager.shared
    @ObservedObject private var studioManager = StudioManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var searchQuery: String = ""
    @State private var showAddStudentSheet: Bool = false
    @State private var selectedStudent: DancerConnection? = nil
    @State private var selectedRoutineItem: IdentifiableRoutineItem? = nil
    
    private var filteredStudents: [DancerConnection] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return connectionManager.activeStudents
        }
        return connectionManager.activeStudents.filter { s in
            s.otherUserName.lowercased().contains(query) ||
            s.otherUserClub.lowercased().contains(query) ||
            s.otherUserDancerCode.lowercased().contains(query)
        }
    }
    
    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            VStack(spacing: 0) {
                // Search bar & Add Action
                topBarSection
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                
                // Student List / Empty State
                if filteredStudents.isEmpty {
                    emptyRosterView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredStudents) { student in
                                studentCardView(for: student)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await refreshAll()
                    }
                }
            }
        }
        .navigationTitle("Trénerský Roster")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddStudentSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text("Pridať")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(LuxuryTheme.gold400)
                }
            }
        }
        .sheet(isPresented: $showAddStudentSheet) {
            AddConnectionSheetView()
        }
        .navigationDestination(item: $selectedRoutineItem) { item in
            StudentRoutineDetailView(
                studentId: item.student.otherUserId,
                studentName: item.student.otherUserName,
                routine: item.routine
            )
        }
        .task {
            await refreshAll()
        }
    }
    
    // MARK: - Top Bar Section
    private var topBarSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                TextField("Hľadať zverenca, klub alebo Dancer ID...", text: $searchQuery)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(LuxuryTheme.obsidian800)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }
    
    // MARK: - Student Card View
    private func studentCardView(for student: DancerConnection) -> some View {
        let routines = studioManager.studentRoutines[student.otherUserId] ?? []
        
        return VStack(alignment: .leading, spacing: 12) {
            // Student Identity Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [LuxuryTheme.gold500, LuxuryTheme.gold300],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text(student.otherUserName.prefix(2).uppercased())
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(LuxuryTheme.obsidian900)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(student.otherUserName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        if !student.otherUserClub.isEmpty {
                            Text(student.otherUserClub)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        
                        // Dancer ID Pill
                        if !student.otherUserDancerCode.isEmpty {
                            Text(student.otherUserDancerCode)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(LuxuryTheme.gold300)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(LuxuryTheme.obsidian900)
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(LuxuryTheme.gold500.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(routines.count)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(LuxuryTheme.gold400)
                    Text("zostáv")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Routines list
            if routines.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Zverenec zatiaľ nevytvoril žiadne zostavy.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(routines, id: \.id) { routine in
                        Button {
                            selectedRoutineItem = IdentifiableRoutineItem(student: student, routine: routine)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "figure.dance")
                                    .font(.system(size: 14))
                                    .foregroundColor(LuxuryTheme.gold400)
                                    .frame(width: 28, height: 28)
                                    .background(LuxuryTheme.gold500.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 6) {
                                        Text(routine.dance_name)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(LuxuryTheme.gold300)
                                        
                                        if let modBy = routine.last_modified_by, !modBy.isEmpty {
                                            Text("• \(modBy)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.55))
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .padding(10)
                            .background(LuxuryTheme.obsidian900.opacity(0.55))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(LuxuryTheme.obsidian800)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 1))
    }
    
    // MARK: - Empty Roster View
    private var emptyRosterView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LuxuryTheme.gold500.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 30))
                    .foregroundColor(LuxuryTheme.gold400)
            }
            
            Text("Žiadni zverenci v rostri")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Pridajte svojich zverencov zadaním ich Dancer ID. Budete mať okamžitý prístup k ich zostavám a môžete im priraďovať figúry.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            Button {
                showAddStudentSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                    Text("Pripojiť prvého zverenca")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(LuxuryTheme.obsidian900)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(LuxuryTheme.gold400)
                .cornerRadius(12)
            }
            .padding(.top, 8)
            Spacer()
        }
    }
    
    private func refreshAll() async {
        await connectionManager.fetchAllConnections()
        for student in connectionManager.activeStudents {
            _ = await studioManager.fetchStudentRoutines(studentUserId: student.otherUserId)
        }
    }
}

// MARK: - Xcode Canvas Preview
#Preview("StudioCoachRosterView - Trénerský Roster") {
    NavigationStack {
        StudioCoachRosterView()
    }
    .previewWithSampleData()
}
