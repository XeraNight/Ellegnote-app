import Testing
import Foundation
import SwiftUI
import SwiftData
@testable import Encore

/// The comparison's helper lines must measure exactly, and a saved correction must land in the figure's
/// notes as one readable line without losing what was already written there.
@MainActor
struct AnalysisToolsTests {

    // MARK: Lines
    @Test func levelLineThroughItsCentreAtTheChosenTilt() {
        var guides = AnalysisGuides()
        guides.moveLevel(toFraction: 0.5)
        guides.setAngle(6)
        let (start, end) = guides.levelEndpoints(in: CGSize(width: 400, height: 800))

        // The centre stays where the line was moved, and the slope is the tilt.
        #expect(abs((start.x + end.x) / 2 - 200) < 0.001)
        #expect(abs((start.y + end.y) / 2 - 400) < 0.001)
        let measured = atan2(end.y - start.y, end.x - start.x) * 180 / .pi
        #expect(abs(measured - 6) < 0.001)
        #expect(guides.roundedAngle == 6)
    }

    @Test func linesStayInsideThePictureAndTiltIsLimited() {
        var guides = AnalysisGuides()
        guides.movePlumb(toFraction: 1.4)
        guides.moveLevel(toFraction: -0.2)
        guides.setAngle(80)
        #expect(guides.plumbX == 1)
        #expect(guides.levelY == 0)
        #expect(guides.levelAngle == AnalysisGuides.maxAngle)

        guides.setAngle(-5.6)
        #expect(guides.roundedAngle == 6)   // the label shows how much, the line shows which way
    }

    // MARK: Correction text
    @Test func correctionLineListsTagsInFixedOrderWithTiltAndNote() throws {
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 9)))
        let correction = FigureCorrection(
            tags: [.timing, .bodyBack, .frameDrops],
            note: "  pomalšie do otočky \n",
            tilt: 6,
            date: date
        )
        #expect(correction.noteLine == "Korekcia 9. 10.: Telo dozadu, Rám padá, Načasovanie · sklon 6° · pomalšie do otočky")
    }

    @Test func emptyCorrectionCannotBeSavedAndZeroTiltIsLeftOut() throws {
        #expect(FigureCorrection(note: "   ").isEmpty)
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        let levelOnly = FigureCorrection(tags: [.head], tilt: 0, date: date)
        #expect(!levelOnly.isEmpty)
        #expect(levelOnly.noteLine == "Korekcia 1. 3.: Hlava")
    }

    // MARK: Notes
    private func makeNode(notes: String) throws -> (ModelContainer, CanvasNode) {
        let schema = Schema([Routine.self, CanvasNode.self, VideoMediaEntry.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let node = CanvasNode(x: 0, y: 0, figureName: "Natural Turn", rhythm: "SQQ", notes: notes, orderIndex: 0)
        container.mainContext.insert(node)
        return (container, node)
    }

    @Test func correctionGoesBelowExistingNotes() throws {
        let (container, node) = try makeNode(notes: "Rám drž hore")
        _ = container
        let updated = RichNote.appending("Korekcia 9. 10.: Hlava", to: node)
        #expect(updated.plain == "Rám drž hore\n\nKorekcia 9. 10.: Hlava")
        #expect(updated.rich == nil)   // plain notes stay plain
    }

    @Test func correctionIsTheFirstLineOfEmptyNotes() throws {
        let (container, node) = try makeNode(notes: "")
        _ = container
        #expect(RichNote.appending("Korekcia 9. 10.: Hlava", to: node).plain == "Korekcia 9. 10.: Hlava")
    }

    @Test func formattedNotesKeepTheirFormatting() throws {
        let (container, node) = try makeNode(notes: "Rám drž hore")
        _ = container
        var formatted = AttributedString("Rám drž hore")
        formatted.font = .system(size: 22, weight: .bold)
        node.notesRichData = RichNote.encode(formatted)

        let updated = RichNote.appending("Korekcia 9. 10.: Hlava", to: node)
        let rich = try #require(updated.rich.flatMap(RichNote.decode))
        #expect(RichNote.plain(rich) == updated.plain)
        let firstRun = try #require(rich.runs.first)
        #expect(firstRun.font == .system(size: 22, weight: .bold))
    }
}
