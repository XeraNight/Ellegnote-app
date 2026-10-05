import SwiftUI
import SwiftData

// MARK: - Main Tab View (native Liquid Glass TabView)
struct MainTabView: View {

    // Tab index: 0 = Domov, 1 = Canvas, 2 = Plán, 3 = Profil
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            // Root velvet stage background covering the whole screen without black bars
            EllegancePageBackground()

            TabView(selection: $selectedTab) {
                Tab("Domov", systemImage: "house.fill", value: 0) {
                    ContentView()
                }

                Tab("Canvas", systemImage: "square.grid.2x2.fill", value: 1) {
                    CanvasRoutinesHubView()
                }

                Tab("Plán", systemImage: "calendar.badge.clock", value: 2) {
                    DancePlannerView()
                }

                Tab("Profil", systemImage: "person.crop.circle.fill", value: 3) {
                    ProfileView()
                }
            }
            .tint(Color.gold400)
        }
        .onAppear {
            // Transparent Navigation Bar
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithTransparentBackground()
            navAppearance.backgroundColor = .clear
            navAppearance.shadowColor = .clear
            let baseFont = UIFont.systemFont(ofSize: 17, weight: .bold)
            let titleFont: UIFont
            if let serifDesc = baseFont.fontDescriptor.withDesign(.serif) {
                titleFont = UIFont(descriptor: serifDesc, size: 17)
            } else {
                titleFont = baseFont
            }
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor(Color.gold500),
                .font: titleFont
            ]
            navAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(Color.gold500)
            ]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
            UINavigationBar.appearance().tintColor = UIColor(Color.gold500)
            UITextView.appearance().backgroundColor = .clear
        }
    }
}

// MARK: - Xcode Canvas Preview (Safe Static Container for Instant Live Preview)
#Preview("MainTabView - App Workspace & Dock") {
    let schema = Schema([
        Dance.self,
        FigureLibraryItem.self,
        Routine.self,
        CanvasNode.self,
        InstantNote.self,
        VideoMediaEntry.self,
        TrainingCadence.self,
        TrainingLogEntry.self,
        PlannedCompetition.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return MainTabView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}



