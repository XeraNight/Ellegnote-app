import Testing
import Foundation
import SwiftData
@testable import Encore

/// Guards the QR share flow on the canvas and in the routine list: a normal routine must always give
/// a QR code, and a routine that is too big must fail cleanly (the sheet then offers the text code).
@MainActor
struct RoutineShareTests {

    private func makeRoutine(figures: Int, noteLength: Int) throws -> (ModelContainer, Routine) {
        let schema = Schema([Routine.self, CanvasNode.self, VideoMediaEntry.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let routine = Routine(name: "Test zostava", danceName: "Quickstep", danceCategory: "Standard")
        container.mainContext.insert(routine)
        for index in 0..<figures {
            let node = CanvasNode(
                x: Double(100 + index * 10),
                y: Double(200 + index * 10),
                figureName: "Figúra \(index + 1)",
                rhythm: "SQQ",
                notes: String(repeating: "a", count: noteLength),
                orderIndex: index
            )
            node.routine = routine
            container.mainContext.insert(node)
        }
        try container.mainContext.save()
        return (container, routine)
    }

    @Test func normalRoutineAlwaysGivesAQRCode() throws {
        let (container, routine) = try makeRoutine(figures: 8, noteLength: 60)
        _ = container

        let payload = try #require(QRGenerator.generatePayload(from: routine))
        #expect(QRGenerator.generateQRCode(from: payload) != nil)

        let decoded = try JSONDecoder().decode(QRSharePayload.self, from: Data(payload.utf8))
        #expect(decoded.n == "Test zostava")
        #expect(decoded.nodes.count == 8)
    }

    @Test func routineTooBigForQRFailsCleanly() throws {
        let (container, routine) = try makeRoutine(figures: 60, noteLength: 300)
        _ = container

        let payload = try #require(QRGenerator.generatePayload(from: routine))
        #expect(payload.utf8.count > 3_000)
        // Too big for a QR code: nil instead of a crash, so the sheet can offer the text code.
        #expect(QRGenerator.generateQRCode(from: payload) == nil)
    }
}
