import Testing
import Foundation
import SwiftData
@testable import Encore

/// Top 3 after a lesson: a new Top 3 replaces the open one for that dance, empty lines are skipped,
/// never more than three, and a Top 3 stays visible until every item is ticked off.
@MainActor
struct LessonPrioritiesTests {

    private func makeContext() throws -> (ModelContainer, ModelContext) {
        let schema = Schema([LessonPriority.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        return (container, container.mainContext)
    }

    private func all(_ context: ModelContext) throws -> [LessonPriority] {
        try context.fetch(FetchDescriptor<LessonPriority>())
    }

    @Test func savesAtMostThreeNonEmptyLinesInOrder() throws {
        let (container, context) = try makeContext()
        _ = container
        let saved = LessonPriorities.save(["  Ramená dole ", "", "Kolená", "Hlava", "Štvrtá"], danceName: "Waltz", in: context)

        #expect(saved.map(\.text) == ["Ramená dole", "Kolená", "Hlava"])
        #expect(saved.map(\.rank) == [1, 2, 3])
        #expect(LessonPriorities.openTexts(for: "Waltz", in: try all(context)) == ["Ramená dole", "Kolená", "Hlava"])
    }

    @Test func emptyLinesSaveNothingAndKeepTheOldTop3() throws {
        let (container, context) = try makeContext()
        _ = container
        LessonPriorities.save(["Ramená dole"], danceName: "Waltz", in: context)
        #expect(LessonPriorities.save(["", "  "], danceName: "Waltz", in: context).isEmpty)
        #expect(LessonPriorities.openTexts(for: "Waltz", in: try all(context)) == ["Ramená dole"])
    }

    @Test func newTop3ReplacesOnlyTheSameDance() throws {
        let (container, context) = try makeContext()
        _ = container
        let first = Date(timeIntervalSince1970: 1_000)
        LessonPriorities.save(["Ramená dole", "Kolená"], danceName: "Waltz", now: first, in: context)
        LessonPriorities.save(["Akcia chodidiel"], danceName: "Tango", now: first, in: context)
        LessonPriorities.save(["Hlava doľava"], danceName: "Waltz", now: first.addingTimeInterval(60), in: context)

        let everything = try all(context)
        #expect(LessonPriorities.openTexts(for: "Waltz", in: everything) == ["Hlava doľava"])
        #expect(LessonPriorities.openTexts(for: "Tango", in: everything) == ["Akcia chodidiel"])
        #expect(everything.filter { $0.replacedAt != nil }.count == 2)   // kept for the data export
        #expect(LessonPriorities.activeSets(everything).map(\.danceName) == ["Waltz", "Tango"])
    }

    @Test func top3StaysUntilEveryItemIsTickedOff() throws {
        let (container, context) = try makeContext()
        _ = container
        let saved = LessonPriorities.save(["Ramená dole", "Kolená"], danceName: "Waltz", in: context)

        saved[0].doneAt = Date()
        var sets = LessonPriorities.activeSets(try all(context))
        #expect(sets.count == 1)
        #expect(sets[0].items.count == 2)   // the ticked one stays visible, crossed out
        #expect(sets[0].openCount == 1)

        saved[1].doneAt = Date()
        sets = LessonPriorities.activeSets(try all(context))
        #expect(sets.isEmpty)
    }
}
