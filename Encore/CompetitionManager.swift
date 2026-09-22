import Foundation
import SwiftUI
import Combine
import Supabase
import Auth

// MARK: - Competition & KSIS Import Manager
@MainActor
public final class CompetitionManager: ObservableObject {
    public static let shared = CompetitionManager()

    // MARK: - Published State
    @Published public var couples: [UserCouple] = []
    @Published public var activeCouple: UserCouple? = nil
    @Published public var results: [CompetitionResult] = []
    @Published public var archivedResults: [CompetitionResult] = []
    @Published public var advancementRules: [AdvancementRule] = []

    @Published public var isLoading: Bool = false
    @Published public var isImporting: Bool = false
    @Published public var previewResult: CompetitionResult? = nil
    @Published public var errorMessage: String? = nil
    @Published public var conflictRestorePayload: (resultId: String, message: String)? = nil

    // 429 Rate Limit Cooldown Countdown
    @Published public var cooldownRemaining: Int = 0

    private var cooldownTimer: Timer? = nil
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Observe auth state changes to reload data
        AuthManager.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                if user != nil {
                    Task {
                        await self?.loadAllData()
                    }
                } else {
                    self?.resetState()
                }
            }
            .store(in: &cancellables)

        Task {
            await loadAllData()
        }
    }

    deinit {
        cooldownTimer?.invalidate()
    }

    public func resetState() {
        couples = []
        activeCouple = nil
        results = []
        archivedResults = []
        previewResult = nil
        errorMessage = nil
        conflictRestorePayload = nil
    }

    // MARK: - Full Reload
    public func loadAllData() async {
        guard AuthManager.shared.isAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }

        async let couplesTask: () = fetchCouples()
        async let resultsTask: () = fetchResults()
        async let archivedTask: () = fetchArchivedResults()
        async let rulesTask: () = fetchAdvancementRules()

        _ = await (couplesTask, resultsTask, archivedTask, rulesTask)
    }

    // MARK: - KSIS Link & ID Extraction Helpers
    public static func extractCoupleId(from input: String) -> Int? {
        var cleaned = input
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("#") {
            cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 1. Check query parameters like ?id=18978 or ?couple_id=18978 or ?par_id=18978 or ?par=18978
        if let regex = try? NSRegularExpression(pattern: #"(?:[?&]|^)(?:couple_id|par_id|par|id)=(\d+)"#, options: .caseInsensitive),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned) {
            return Int(cleaned[range])
        }

        // 2. Check URL path patterns like /par/18978
        if let regex = try? NSRegularExpression(pattern: #"/(?:par|couple)/(\d+)"#, options: .caseInsensitive),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned) {
            return Int(cleaned[range])
        }

        // 3. Strip thousand separators (spaces, dots, commas, apostrophes, slashes) and check if pure number
        let digitsOnly = cleaned
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "/", with: "")

        if let id = Int(digitsOnly), id > 0 {
            return id
        }

        // 4. Fallback: match any 3 to 7 digit sequence
        if let regex = try? NSRegularExpression(pattern: #"\b(\d{3,7})\b"#),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned) {
            return Int(cleaned[range])
        }

        return nil
    }

    public static func extractSutazId(from input: String) -> Int? {
        var cleaned = input
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("#") {
            cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 1. Check query parameters like ?sutaz_id=12094 or ?id=12094 or ?sutaz=12094
        if let regex = try? NSRegularExpression(pattern: #"(?:[?&]|^)(?:sutaz_id|sutaz|id)=(\d+)"#, options: .caseInsensitive),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned) {
            return Int(cleaned[range])
        }

        // 2. Check URL path patterns like /sutaz/12094 or /sutaz.php/12094
        if let regex = try? NSRegularExpression(pattern: #"/(?:sutaz|sutaz_id)/(\d+)"#, options: .caseInsensitive),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned) {
            return Int(cleaned[range])
        }

        // 3. Strip thousand separators (spaces, dots, commas, apostrophes, slashes) and check if pure number
        let digitsOnly = cleaned
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "/", with: "")

        if let id = Int(digitsOnly), id > 0 {
            return id
        }

        // 4. Fallback: match any 3 to 7 digit sequence
        if let regex = try? NSRegularExpression(pattern: #"\b(\d{3,7})\b"#),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned) {
            return Int(cleaned[range])
        }

        return nil
    }

    // MARK: - Network Request Helper for Edge Functions
    private func invokeFunction<Req: Encodable, Res: Decodable>(
        name: String,
        body: Req
    ) async throws -> Res {
        guard let session = try? await SupabaseConfig.client.auth.session else {
            throw NSError(
                domain: "EncoreKSIS",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Pre túto akciu sa musíte prihlásiť do svojho účtu."]
            )
        }

        let functionURL = SupabaseConfig.url.appendingPathComponent("functions/v1/\(name)")
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20.0
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "EncoreKSIS",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Neplatná odpoveď zo servera."]
            )
        }

        // Check for rate limit 429
        if httpResponse.statusCode == 429 {
            var retrySeconds = 10
            if let header = httpResponse.value(forHTTPHeaderField: "Retry-After"), let sec = Int(header) {
                retrySeconds = sec
            }
            startCooldown(seconds: retrySeconds)
            let errMsg = "KSIS rate limit: Počkajte \(retrySeconds) sekúnd pred ďalším importom."
            throw NSError(domain: "EncoreKSIS", code: 429, userInfo: [NSLocalizedDescriptionKey: errMsg])
        }

        // Check for conflict 409 (e.g. soft-deleted row)
        if httpResponse.statusCode == 409 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let msg = (json["message"] as? String) ?? (json["error"] as? String) ?? "Tento výsledok už existuje v denníku."
                let canRestore = json["can_restore"] as? Bool ?? false
                let conflictId = (json["existing_result_id"] as? String) ?? (json["conflict_id"] as? String) ?? ""
                if canRestore && !conflictId.isEmpty {
                    self.conflictRestorePayload = (resultId: conflictId, message: msg)
                }
                throw NSError(domain: "EncoreKSIS", code: 409, userInfo: [NSLocalizedDescriptionKey: msg])
            }
        }

        // Check for other error codes
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let msg = (json["message"] as? String) ?? (json["error"] as? String)
                if let msg = msg, !msg.isEmpty {
                    throw NSError(domain: "EncoreKSIS", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }
            }
            throw NSError(
                domain: "EncoreKSIS",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Chyba servera (\(httpResponse.statusCode))."]
            )
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Res.self, from: data)
        } catch {
            print("[invokeFunction] JSON decoding error for \(name): \(error)")
            throw NSError(
                domain: "EncoreKSIS",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Odpoveď servera nemala očakávanú štruktúru údajov. Skúste akciu zopakovať."]
            )
        }
    }

    // MARK: - Cooldown Timer
    private func startCooldown(seconds: Int) {
        cooldownTimer?.invalidate()
        cooldownRemaining = max(seconds, 1)
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.cooldownRemaining > 1 {
                    self.cooldownRemaining -= 1
                } else {
                    self.cooldownRemaining = 0
                    self.cooldownTimer?.invalidate()
                    self.cooldownTimer = nil
                }
            }
        }
    }

    // MARK: - Couple Management
    public func fetchCouples() async {
        // Direct query to Supabase via RLS for maximum reliability
        do {
            let client = SupabaseConfig.client
            let fetched: [UserCouple] = try await client
                .from("user_couples")
                .select()
                .order("created_at", ascending: true)
                .execute()
                .value
            self.couples = fetched
            if self.activeCouple == nil || !fetched.contains(where: { $0.coupleId == self.activeCouple?.coupleId }) {
                self.activeCouple = fetched.first
            }
        } catch {
            print("[CompetitionManager] direct fetchCouples notice: \(error.localizedDescription)")
            // Fallback to Edge function if needed
            do {
                let req = KSISCoupleActionRequest(action: "list")
                let res: KSISCoupleActionResponse = try await invokeFunction(name: "ksis-manage-couples", body: req)
                if let fetched = res.couples {
                    self.couples = fetched
                    if self.activeCouple == nil || !fetched.contains(where: { $0.coupleId == self.activeCouple?.coupleId }) {
                        self.activeCouple = fetched.first
                    }
                }
            } catch {
                print("[CompetitionManager] fetchCouples function fallback notice: \(error.localizedDescription)")
            }
        }
    }

    public func addCouple(coupleId: Int, discipline: String = "ALL", partnerName: String, partnerConsent: Bool) async throws {
        guard partnerConsent else {
            throw NSError(
                domain: "EncoreKSIS",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Pre prepojenie páru je potrebný súhlas partnera so spracovaním súťažných údajov."]
            )
        }

        let req = KSISCoupleActionRequest(
            action: "add",
            couple_id: coupleId,
            discipline: discipline,
            partner_name: partnerName,
            partner_consent: partnerConsent
        )
        let res: KSISCoupleActionResponse = try await invokeFunction(name: "ksis-manage-couples", body: req)
        await fetchCouples()
        if let created = res.couple {
            self.activeCouple = created
        }
    }

    public func removeCouple(coupleId: Int) async throws {
        let req = KSISCoupleActionRequest(action: "remove", couple_id: coupleId)
        let _: KSISCoupleActionResponse = try await invokeFunction(name: "ksis-manage-couples", body: req)
        await fetchCouples()
    }

    // MARK: - Results & Rules Queries (Direct Supabase SELECT via RLS)
    public func fetchResults() async {
        do {
            let client = SupabaseConfig.client
            let fetched: [CompetitionResult] = try await client
                .from("competition_results")
                .select()
                .eq("is_deleted", value: false)
                .order("date", ascending: false)
                .execute()
                .value
            self.results = fetched
        } catch {
            print("[CompetitionManager] fetchResults notice: \(error.localizedDescription)")
        }
    }

    public func fetchArchivedResults() async {
        do {
            let client = SupabaseConfig.client
            let fetched: [CompetitionResult] = try await client
                .from("competition_results")
                .select()
                .eq("is_deleted", value: true)
                .order("date", ascending: false)
                .execute()
                .value
            self.archivedResults = fetched
        } catch {
            print("[CompetitionManager] fetchArchivedResults notice: \(error.localizedDescription)")
        }
    }

    public func fetchAdvancementRules() async {
        do {
            let client = SupabaseConfig.client
            let rules: [AdvancementRule] = try await client
                .from("advancement_rules")
                .select()
                .execute()
                .value
            self.advancementRules = rules
        } catch {
            print("[CompetitionManager] fetchAdvancementRules notice: \(error.localizedDescription)")
        }
    }

    // MARK: - Import Flow (Preview -> Confirm)
    public func previewResult(sutazId: Int, coupleId: Int? = nil) async throws -> CompetitionResult {
        guard cooldownRemaining == 0 else {
            throw NSError(
                domain: "EncoreKSIS",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "Rate limit: Počkajte \(cooldownRemaining)s."]
            )
        }

        // Auto-resolve coupleId if missing
        var resolvedCoupleId = coupleId ?? activeCouple?.coupleId ?? couples.first?.coupleId ?? 0
        if resolvedCoupleId == 0 {
            await fetchCouples()
            resolvedCoupleId = activeCouple?.coupleId ?? couples.first?.coupleId ?? 0
        }

        guard resolvedCoupleId > 0 else {
            throw NSError(
                domain: "EncoreKSIS",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Najprv si prosím prepojte tanečný pár pomocou tlačidla 'Prepojiť Pár'."]
            )
        }

        isImporting = true
        errorMessage = nil
        conflictRestorePayload = nil
        defer { isImporting = false }

        let req = KSISImportRequest(sutaz_id: sutazId, couple_id: resolvedCoupleId, preview_only: true)
        let res: KSISImportResponse = try await invokeFunction(name: "ksis-import", body: req)
        guard let preview = res.resolvedResult else {
            throw NSError(
                domain: "EncoreKSIS",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: res.message ?? res.error ?? "Nepodarilo sa načítať náhľad výsledku."]
            )
        }
        self.previewResult = preview
        return preview
    }

    public func confirmImport(sutazId: Int, coupleId: Int? = nil) async throws -> CompetitionResult {
        guard cooldownRemaining == 0 else {
            throw NSError(
                domain: "EncoreKSIS",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "Rate limit: Počkajte \(cooldownRemaining)s."]
            )
        }

        var resolvedCoupleId = coupleId ?? activeCouple?.coupleId ?? couples.first?.coupleId ?? 0
        if resolvedCoupleId == 0 {
            await fetchCouples()
            resolvedCoupleId = activeCouple?.coupleId ?? couples.first?.coupleId ?? 0
        }

        guard resolvedCoupleId > 0 else {
            throw NSError(
                domain: "EncoreKSIS",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Najprv si prosím prepojte tanečný pár."]
            )
        }

        isImporting = true
        errorMessage = nil
        conflictRestorePayload = nil
        defer { isImporting = false }

        let req = KSISImportRequest(sutaz_id: sutazId, couple_id: resolvedCoupleId, preview_only: false)
        let res: KSISImportResponse = try await invokeFunction(name: "ksis-import", body: req)
        guard let imported = res.resolvedResult else {
            throw NSError(
                domain: "EncoreKSIS",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: res.message ?? res.error ?? "Import výsledku zlyhal."]
            )
        }

        // Successful import starts 10s cooldown per rate limit contract
        startCooldown(seconds: 10)
        self.previewResult = nil
        await fetchResults()
        return imported
    }

    // MARK: - Soft Delete & Restore
    public func softDeleteResult(resultId: UUID) async throws {
        let req = KSISManageResultsRequest(action: "soft_delete", result_id: resultId.uuidString)
        let _: KSISManageResultsResponse = try await invokeFunction(name: "ksis-manage-results", body: req)
        await fetchResults()
        await fetchArchivedResults()
    }

    public func restoreResult(resultId: UUID) async throws {
        let req = KSISManageResultsRequest(action: "restore", result_id: resultId.uuidString)
        let _: KSISManageResultsResponse = try await invokeFunction(name: "ksis-manage-results", body: req)
        self.conflictRestorePayload = nil
        await fetchResults()
        await fetchArchivedResults()
    }

    // MARK: - Class Advancement Calculator
    public struct AdvancementProgress {
        public let currentPoints: Int
        public let requiredPoints: Int
        public let currentFinals: Int
        public let requiredFinals: Int
        public let pointsProgress: Double
        public let finalsProgress: Double
        public let isAdvancementEarned: Bool
        public let pointsNeeded: Int
        public let finalsNeeded: Int
        public let ruleName: String
    }

    public func computeAdvancement(for coupleId: Int?, discipline: String? = nil) -> AdvancementProgress {
        let relevantResults: [CompetitionResult]
        if let coupleId = coupleId {
            relevantResults = results.filter {
                $0.coupleId == coupleId &&
                (discipline == nil || discipline == "Všetko" || $0.discipline.uppercased() == discipline?.uppercased())
            }
        } else {
            relevantResults = results
        }

        // KSIS official source of truth: The most recent official result with cumulativeStats
        // e.g. "89/5F"
        var currentPoints = 0
        var currentFinals = 0

        if let latestWithStats = relevantResults.first(where: { ($0.cumulativePoints != nil || $0.cumulativeFinals != nil) }) {
            currentPoints = latestWithStats.cumulativePoints ?? 0
            currentFinals = latestWithStats.cumulativeFinals ?? 0
        } else {
            // Fallback: sum earned points and count finals
            currentPoints = relevantResults.compactMap { $0.pointsEarned }.reduce(0, +)
            currentFinals = relevantResults.filter { $0.isFinalPlacement }.count
        }

        // Default SZTŠ D -> C rule: 200 points + 5 finals
        let rule = advancementRules.first ?? AdvancementRule(
            category: "Dospelí",
            fromClass: "D",
            toClass: "C",
            requiredPoints: 200,
            requiredFinals: 5
        )

        let reqPoints = rule.requiredPoints
        let reqFinals = rule.requiredFinals

        let pointsProgress = min(1.0, Double(currentPoints) / Double(max(1, reqPoints)))
        let finalsProgress = min(1.0, Double(currentFinals) / Double(max(1, reqFinals)))

        let earned = currentPoints >= reqPoints && currentFinals >= reqFinals
        let ptsNeeded = max(0, reqPoints - currentPoints)
        let finNeeded = max(0, reqFinals - currentFinals)

        return AdvancementProgress(
            currentPoints: currentPoints,
            requiredPoints: reqPoints,
            currentFinals: currentFinals,
            requiredFinals: reqFinals,
            pointsProgress: pointsProgress,
            finalsProgress: finalsProgress,
            isAdvancementEarned: earned,
            pointsNeeded: ptsNeeded,
            finalsNeeded: finNeeded,
            ruleName: rule.ruleDescription
        )
    }
}
