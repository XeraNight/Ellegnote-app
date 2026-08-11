import SwiftUI
import SwiftData

@main
struct EllegnoteApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Dance.self,
            FigureLibraryItem.self,
            Routine.self,
            CanvasNode.self,
            InstantNote.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            print("ModelContainer init failed: \(error). Attempting recovery…")
            do {
                container = try DatabaseRecoveryManager.recoverContainer(schema: schema, configuration: config)
            } catch {
                fatalError("Could not initialize ModelContainer after recovery: \(error)")
            }
        }

        // Seed on a true background task — never touches the main thread
        let containerRef = container
        Task.detached(priority: .background) {
            await EllegnoteApp.seedIfNeeded(container: containerRef)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    Task { await AuthManager.shared.handleDeepLink(url) }
                }
        }
        .modelContainer(container)
    }

    // MARK: - Background seed using a dedicated ModelActor context
    // Runs entirely off the main thread — zero impact on first-frame render.
    private static func seedIfNeeded(container: ModelContainer) async {
        // Create a background context (ModelActor) for safe off-thread access
        let bgContext = ModelContext(container)

        var fetch = FetchDescriptor<Dance>()
        fetch.fetchLimit = 1

        do {
            let existing = try bgContext.fetch(fetch)
            guard existing.isEmpty else { return }   // already seeded
            populateDefaultData(context: bgContext)
        } catch {
            print("Seed check failed: \(error)")
        }
    }

    private static func populateDefaultData(context: ModelContext) {
        // Standard Dances
        let dances: [(String, String, String, String)] = [
            ("Waltz",          "Standard", "28–30 MPM (84–90 BPM)",   "Sústreď sa na Rise & Fall. Klesanie prebieha na konci doby 3, zdvih začína na 1. Dôležitý je aj Sway."),
            ("Tango",          "Standard", "31–33 MPM (124–132 BPM)", "Tango nemá Rise & Fall. Pohyb je ostrý, staccato. Držanie je kompaktnejšie a kolená sú neustále mierne pokrčené."),
            ("Viennese Waltz", "Standard", "58–60 MPM (174–180 BPM)", "Pri tej rýchlosti je kľúčová rotácia a plynulosť. Sústreď sa na čisté otáčky a prechodové kroky."),
            ("Slowfoxtrot",    "Standard", "28–30 MPM (112–120 BPM)", "Najťažší tanec na techniku. Vyžaduje lineárny pohyb a extrémne tiché dopady. Rytmizácia je väčšinou Slow, Quick, Quick."),
            ("Quickstep",      "Standard", "50–52 MPM (200–208 BPM)", "Vyhýbaj sa skákaniu. Pruženie vychádza z členkov a kolien, zatiaľ čo vrchná časť tela zostáva pokojná."),
            ("Samba",          "Latin",    "48–50 MPM (96–100 BPM)",  "Základom je Samba Bounce. Nejde o skákanie, ale o prácu s panvou v rytme 1 a 2."),
            ("Cha-Cha-Cha",    "Latin",    "30–32 MPM (120–128 BPM)", "Akcent je na dobu 1. Kroky musia byť ostré, nohy prepnuté a váha musí byť vpredu na bruškách chodidiel."),
            ("Rumba",          "Latin",    "25–27 MPM (100–108 BPM)", "Tanec lásky. Veď pohyb z centra tela a doťahuj každý krok. Jednotka sa netancuje."),
            ("Paso Doble",     "Latin",    "60–62 MPM (120–124 BPM)", "Muž je toreador, žena muleta. Vysoké držanie, podsadená panva a silný očný kontakt."),
            ("Jive",           "Latin",    "42–44 MPM (168–176 BPM)", "Vyžaduje kondíciu. Odraz z brušiek a swingový charakter. Jive nie je len o nohách.")
        ]
        for (name, cat, tempo, info) in dances {
            context.insert(Dance(name: name, category: cat, tempo: tempo, info: info))
        }

        FigureLibraryItem.seedDefaultFigures(in: context)

        try? context.save()
    }
}
