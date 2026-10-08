import Testing
import Foundation
@testable import Encore

/// Videos recorded on Home live in Fotky and are stored as `photos:<id>` in the same `videoPath` fields
/// as app files. The two must never be mixed up: a Fotky reference is not a file name and not a Supabase path.
@MainActor
struct VideoReferenceTests {

    @Test func fotkyReferenceIsRecognised() {
        #expect(PhotoLibraryVideoStore.isReference("photos:ABC-123/L0/001"))
        #expect(!PhotoLibraryVideoStore.isReference("3F2A9C1E-video.mp4"))
        #expect(!PhotoLibraryVideoStore.isReference(""))
    }

    @Test func fotkyReferenceNeverBecomesAStorageURL() {
        #expect(MediaResolver.resolveVideoURL(path: "photos:ABC-123/L0/001") == nil)
    }

    @Test func fotkyReferenceIsNotAnImage() {
        #expect(!MediaResolver.isImagePath(path: "photos:ABC-123/L0/001"))
    }
}
