import Foundation
import SwiftUI
import Combine
import Supabase
import Auth

// MARK: - Per-Account Profile & Preferences Manager
// Isolates profile information (name, club, avatar, preferences) per account,
// ensuring no newly registered user inherits stale data from previous users or guest accounts.
@MainActor
final class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()
    
    @Published var currentName: String = ""
    @Published var currentClub: String = ""
    @Published var currentAvatarPath: String? = nil
    @Published var currentLanguage: String = "sk-SK"
    @Published var currentPlaybackRate: Double = 1.0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        refreshForActiveUser()
        
        // Listen to AuthManager changes to dynamically switch profile context
        AuthManager.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshForActiveUser()
            }
            .store(in: &cancellables)
        
        AuthManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshForActiveUser()
            }
            .store(in: &cancellables)
    }
    
    /// Unique identifier for the currently active session:
    /// - Authenticated Supabase UUID if logged in
    /// - Cleaned email address if available
    /// - "guest" for local offline mode
    /// .
    var activeUserId: String {
        if let id = AuthManager.shared.currentUser?.id.uuidString {
            return id.lowercased()
        }
        let email = AuthManager.shared.userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !email.isEmpty {
            return email.replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_")
        }
        return "guest"
    }
    
    /// Loads the active account's profile data from user-scoped storage
    func refreshForActiveUser() {
        let uid = activeUserId
        let defaults = UserDefaults.standard
        
        // 1. Name: Account-scoped, then Supabase metadata / AuthManager, then fallback
        let savedName = defaults.string(forKey: "profileName_\(uid)")
        if let savedName = savedName, !savedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentName = savedName
        } else if !AuthManager.shared.userName.isEmpty && AuthManager.shared.userName != "Tanečník" && AuthManager.shared.userName != "Jakub" {
            currentName = AuthManager.shared.userName
        } else if uid == "guest" {
            currentName = defaults.string(forKey: "profileName") ?? "Tanečník"
        } else {
            let fallbackName = AuthManager.shared.userName
            currentName = (fallbackName.isEmpty || fallbackName == "Jakub") ? "Tanečník" : fallbackName
        }
        
        // 2. Club: Account-scoped. Brand new accounts have NO club by default!
        if let savedClub = defaults.string(forKey: "profileClub_\(uid)") {
            currentClub = savedClub
        } else if uid == "guest" {
            currentClub = defaults.string(forKey: "profileClub") ?? ""
        } else {
            currentClub = "" // Never inherit another account's club
        }
        
        // 3. Avatar: Account-scoped. Brand new accounts have NO photo by default!
        if let savedAvatar = defaults.string(forKey: "profileAvatarPath_\(uid)"), !savedAvatar.isEmpty {
            currentAvatarPath = savedAvatar
        } else if uid == "guest" {
            currentAvatarPath = defaults.string(forKey: "profileImagePath")
        } else {
            currentAvatarPath = nil // Never inherit another account's photo
        }
        
        // 4. Dictation Language
        let savedLang = defaults.string(forKey: "profileLang_\(uid)")
        currentLanguage = savedLang ?? defaults.string(forKey: "defaultDictationLanguage") ?? "sk-SK"
        
        // 5. Playback Rate
        let savedRate = defaults.double(forKey: "profileRate_\(uid)")
        if savedRate > 0 {
            currentPlaybackRate = savedRate
        } else {
            let legacyRate = defaults.double(forKey: "defaultPlaybackRate")
            currentPlaybackRate = legacyRate > 0 ? legacyRate : 1.0
        }
    }
    
    /// Saves updated name and club for the active account
    func saveProfile(name: String, club: String) {
        let uid = activeUserId
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClub = club.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalName = trimmedName.isEmpty ? "Tanečník" : trimmedName
        currentName = finalName
        currentClub = trimmedClub
        
        let defaults = UserDefaults.standard
        defaults.set(finalName, forKey: "profileName_\(uid)")
        defaults.set(trimmedClub, forKey: "profileClub_\(uid)")
        
        // Keep AuthManager and global fallback in sync
        AuthManager.shared.userName = finalName
        defaults.set(finalName, forKey: "profileName")
        if uid == "guest" {
            defaults.set(trimmedClub, forKey: "profileClub")
        }
    }
    
    /// Updates or clears avatar image path for the active account
    func setAvatarPath(_ path: String?) {
        let uid = activeUserId
        let defaults = UserDefaults.standard
        
        currentAvatarPath = path
        if let path = path, !path.isEmpty {
            defaults.set(path, forKey: "profileAvatarPath_\(uid)")
            if uid == "guest" {
                defaults.set(path, forKey: "profileImagePath")
            }
        } else {
            defaults.removeObject(forKey: "profileAvatarPath_\(uid)")
            if uid == "guest" {
                defaults.removeObject(forKey: "profileImagePath")
            }
        }
    }
    
    /// Updates preferred dictation language for the active account
    func setLanguage(_ lang: String) {
        let uid = activeUserId
        currentLanguage = lang
        UserDefaults.standard.set(lang, forKey: "profileLang_\(uid)")
        UserDefaults.standard.set(lang, forKey: "defaultDictationLanguage")
    }
    
    /// Updates preferred video playback rate for the active account
    func setPlaybackRate(_ rate: Double) {
        let uid = activeUserId
        currentPlaybackRate = rate
        UserDefaults.standard.set(rate, forKey: "profileRate_\(uid)")
        UserDefaults.standard.set(rate, forKey: "defaultPlaybackRate")
    }
}
