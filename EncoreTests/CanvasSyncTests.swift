import Testing
import Foundation
import SwiftData
@testable import Encore

/// A sync from the server (refresh, realtime, partner edits) must never wipe what lives only on this
/// iPhone: the original video in Fotky, its rotation and the mastery rating.
@MainActor
struct CanvasSyncTests {

    private func row(id: UUID, videoPath: String?) -> DBCanvasNodeRow {
        DBCanvasNodeRow(
            id: id, routine_id: UUID(), x: 300, y: 400,
            figure_name: "Natural Turn", rhythm: "123", notes: "Od partnerky",
            video_path: videoPath, order_index: 2, transition_notes: "Prechod",
            coach_notes: "Viac švihu", coach_notes_by_name: "Tréner", coach_notes_at: nil
        )
    }

    @Test func serverRowNeverTouchesTheOriginalVideo() {
        let node = CanvasNode(x: 10, y: 20, figureName: "Old", videoPath: "photos:MY-ORIGINAL")
        node.videoRotation = 90
        node.masteryRating = 5

        node.apply(row: row(id: node.id, videoPath: "shared/copy.mp4"), includingPosition: true)

        #expect(node.videoPath == "photos:MY-ORIGINAL")
        #expect(node.videoRotation == 90)
        #expect(node.masteryRating == 5)
        #expect(node.sharedVideoPath == "shared/copy.mp4")
        #expect(node.notes == "Od partnerky")
        #expect(node.coachNotes == "Viac švihu")
    }

    @Test func ownOriginalWinsOverTheSharedCopy() {
        let node = CanvasNode(x: 0, y: 0, figureName: "Whisk", videoPath: "photos:MINE")
        node.sharedVideoPath = "shared/copy.mp4"
        #expect(node.displayVideoPath == "photos:MINE")

        node.videoPath = nil   // e.g. the partner's iPhone
        #expect(node.displayVideoPath == "shared/copy.mp4")
    }

    @Test func positionIsKeptWhileDragging() {
        let node = CanvasNode(x: 10, y: 20, figureName: "Old")
        node.apply(row: row(id: node.id, videoPath: nil), includingPosition: false)
        #expect(node.x == 10 && node.y == 20)
        #expect(node.figureName == "Natural Turn")
    }

    @Test func figureFromServerStartsWithoutAnOriginal() {
        let node = CanvasNode(row: row(id: UUID(), videoPath: "shared/copy.mp4"))
        #expect(node.videoPath == nil)
        #expect(node.sharedVideoPath == "shared/copy.mp4")
        #expect(node.x == 300 && node.y == 400)
    }
}
