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
            seedInitialDataIfNeeded()
        } catch {
            print("ModelContainer failed to initialize: \(error). Attempting database recovery...")
            do {
                container = try DatabaseRecoveryManager.recoverContainer(schema: schema, configuration: config)
                seedInitialDataIfNeeded()
            } catch {
                fatalError("Could not initialize ModelContainer after recovery: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
    
    @MainActor
    private func seedInitialDataIfNeeded() {
        let context = container.mainContext
        
        // Check if dances already exist
        let danceFetch = FetchDescriptor<Dance>()
        do {
            let existingDances = try context.fetch(danceFetch)
            if existingDances.isEmpty {
                // Populate default dances and figures
                populateDefaultData(context: context)
            }
        } catch {
            print("Failed to fetch existing dances: \(error)")
        }
    }
    
    @MainActor
    private func populateDefaultData(context: ModelContext) {
        // Standard Dances
        let waltz = Dance(
            name: "Waltz",
            category: "Standard",
            tempo: "28–30 MPM (84–90 BPM)",
            info: "Sústreď sa na Rise & Fall (zdvih a klesanie). Klesanie prebieha na konci doby 3, zdvih začína na 1. Dôležitý je aj Sway (náklon), ktorý pomáha vyvažovať rotáciu."
        )
        let tango = Dance(
            name: "Tango",
            category: "Standard",
            tempo: "31–33 MPM (124–132 BPM)",
            info: "Tango nemá Rise & Fall. Pohyb je ostrý, staccato. Na rozdiel od ostatných tancov je držanie kompaktnejšie a kolená sú neustále mierne pokrčené."
        )
        let vWaltz = Dance(
            name: "Viennese Waltz",
            category: "Standard",
            tempo: "58–60 MPM (174–180 BPM)",
            info: "Pri tej rýchlosti je kľúčová rotácia a plynulosť. Fleckerly sú náročné na rovnováhu; v základnej zostave sa sústreď hlavne na čisté otáčky a prechodové kroky."
        )
        let slowfoxtrot = Dance(
            name: "Slowfoxtrot",
            category: "Standard",
            tempo: "28–30 MPM (112–120 BPM)",
            info: "Najťažší tanec na techniku. Vyžaduje lineárny pohyb a extrémne tiché dopady. Rytmizácia je väčšinou 'Slow, Quick, Quick'."
        )
        let quickstep = Dance(
            name: "Quickstep",
            category: "Standard",
            tempo: "50–52 MPM (200–208 BPM)",
            info: "Vyhýbaj sa 'skákaniu' celým telom. Pruženie vychádza z členkov a kolien, zatiaľ čo vrchná časť tela zostáva pokojná a stabilná."
        )
        
        // Latin Dances
        let samba = Dance(
            name: "Samba",
            category: "Latin",
            tempo: "48–50 MPM (96–100 BPM)",
            info: "Základom je Samba Bounce (pruženie v kolenách). Nejde o skákanie hore-dole, ale o prácu s panvou (stláčanie kolien v rytme 1 a 2)."
        )
        let chacha = Dance(
            name: "Cha-Cha-Cha",
            category: "Latin",
            tempo: "30–32 MPM (120–128 BPM)",
            info: "Akcent je na dobu 1. Kroky musia byť ostré, nohy prepnuté a váha musí byť vpredu na bruškách chodidiel."
        )
        let rumba = Dance(
            name: "Rumba",
            category: "Latin",
            tempo: "25–27 MPM (100–108 BPM)",
            info: "Tanec lásky a interpretácie. Dôležité je viesť pohyb z centra tela a doťahovať každý krok. 'Jednotka' sa netancuje (je to pauza/dokončenie pohybu)."
        )
        let pasoDoble = Dance(
            name: "Paso Doble",
            category: "Latin",
            tempo: "60–62 MPM (120–124 BPM)",
            info: "Muž je toreador, žena je muleta (šatka). Charakterizujú ho vysoké držanie, podsadená panva a silný očný kontakt."
        )
        let jive = Dance(
            name: "Jive",
            category: "Latin",
            tempo: "42–44 MPM (168–176 BPM)",
            info: "Vyžaduje vysokú kondíciu. Dôležitý je odraz z brušiek a 'swingový' charakter. Jive nie je len o nohách, ale aj o rytmickom pohybe celého tela."
        )
        
        context.insert(waltz)
        context.insert(tango)
        context.insert(vWaltz)
        context.insert(slowfoxtrot)
        context.insert(quickstep)
        context.insert(samba)
        context.insert(chacha)
        context.insert(rumba)
        context.insert(pasoDoble)
        context.insert(jive)
        
        // Figures Seeding
        FigureLibraryItem.seedDefaultFigures(in: context)
        
        try? context.save()
        print("Successfully seeded dances and figures library.")
    }
}
