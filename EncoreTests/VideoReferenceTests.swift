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

/// Shared copies (`r2:`) are the only video paths allowed on the server; the database refuses others
/// and a refused path would fail the whole routine upload.
@MainActor
struct SharedVideoPathTests {

    @Test func onlySharedCopiesGoToTheServer() {
        let shared = "r2:3f2a9c1e-0000-4000-8000-000000000000/7b1d2e3f-0000-4000-8000-000000000000.mp4"
        #expect(SharedVideoStore.serverValue(shared) == shared)
        #expect(SharedVideoStore.serverValue("photos:ABC/L0/001") == nil)
        #expect(SharedVideoStore.serverValue("legacy-file.mp4") == nil)
        #expect(SharedVideoStore.serverValue(nil) == nil)
    }

    @Test func sharedCopyIsNeitherAFileNorAFotkyLink() {
        let shared = "r2:owner/clip.mp4"
        #expect(SharedVideoStore.isReference(shared))
        #expect(!PhotoLibraryVideoStore.isReference(shared))
        #expect(MediaResolver.resolveVideoURL(path: shared) == nil)
    }

    @Test func planLimitsMatchTheServer() {
        // public.shared_video_quota_bytes: 1 / 10 / 50 GB
        #expect(SubscriptionTier.free.sharedVideoStorage == "1 GB")
        #expect(SubscriptionTier.plus.sharedVideoStorage == "10 GB")
        #expect(SubscriptionTier.premium.sharedVideoStorage == "50 GB")
    }
}
