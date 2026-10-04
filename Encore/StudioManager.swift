import Foundation
import SwiftUI
import Combine
import Supabase
import OSLog

// MARK: - Studio & Coach Management Service
@MainActor
final class StudioManager: ObservableObject {
    static let shared = StudioManager()
    
    @Published var studentRoutines: [UUID: [DBRoutineRow]] = [:]
    @Published var routineNodes: [UUID: [DBCanvasNodeRow]] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Clear caches when user logs out
        AuthManager.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                if user == nil {
                    self?.reset()
                }
            }
            .store(in: &cancellables)
    }
    
    func reset() {
        studentRoutines = [:]
        routineNodes = [:]
        isLoading = false
        errorMessage = nil
    }
    
    // MARK: - Fetch Student Routines (Supabase RLS Protected)
    func fetchStudentRoutines(studentUserId: UUID) async -> [DBRoutineRow] {
        let client = SupabaseConfig.client
        isLoading = true
        defer { isLoading = false }
        
        do {
            let rows: [DBRoutineRow] = try await client
                .from("routines")
                .select()
                .eq("user_id", value: studentUserId)
                .order("updated_at", ascending: false)
                .execute()
                .value
            
            self.studentRoutines[studentUserId] = rows
            return rows
        } catch {
            print("[StudioManager] fetchStudentRoutines error: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Fetch Canvas Nodes for Routine
    func fetchRoutineNodes(routineId: UUID) async -> [DBCanvasNodeRow] {
        let client = SupabaseConfig.client
        
        do {
            let nodes: [DBCanvasNodeRow] = try await client
                .from("canvas_nodes")
                .select()
                .eq("routine_id", value: routineId)
                .order("order_index", ascending: true)
                .execute()
                .value
            
            self.routineNodes[routineId] = nodes
            return nodes
        } catch {
            print("[StudioManager] fetchRoutineNodes error: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Assign Figure From Coach Library to Student Routine
    func assignFigureToStudentRoutine(
        routineId: UUID,
        figureName: String,
        rhythm: String,
        coachNotes: String,
        transitionNotes: String = "Priradené trénerom"
    ) async throws {
        let client = SupabaseConfig.client
        
        // 1. Fetch current nodes to calculate next orderIndex & positioning
        var currentNodes = routineNodes[routineId] ?? []
        if currentNodes.isEmpty {
            currentNodes = await fetchRoutineNodes(routineId: routineId)
        }
        let nextIndex = (currentNodes.map(\.order_index).max() ?? -1) + 1
        
        // Compute smart ballroom floor coordinates (e.g., stagger on dance floor)
        let lastNode = currentNodes.last
        let nextX = lastNode != nil ? min(lastNode!.x + 120, 780) : 160.0
        let nextY = lastNode != nil ? min(lastNode!.y + 100, 1100) : 180.0
        
        let newNode = DBCanvasNodeRow(
            id: UUID(),
            routine_id: routineId,
            x: nextX,
            y: nextY,
            figure_name: figureName,
            rhythm: rhythm,
            notes: coachNotes,
            video_path: nil,
            order_index: nextIndex,
            transition_notes: transitionNotes
        )
        
        // 2. Insert into canvas_nodes
        try await client
            .from("canvas_nodes")
            .insert(newNode)
            .execute()
        
        // 3. Mark routine with Coach signature in last_modified_by
        let coachName = UserProfileStore.shared.currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let signature = coachName.isEmpty || coachName == "Tanečník" ? "Tréner" : "\(coachName) (Tréner)"
        
        struct RoutineUpdateDTO: Encodable {
            let last_modified_by: String
            let updated_at: String
        }
        
        let nowISO = ISO8601DateFormatter().string(from: Date())
        try await client
            .from("routines")
            .update(RoutineUpdateDTO(last_modified_by: signature, updated_at: nowISO))
            .eq("id", value: routineId)
            .execute()
        
        // 4. Update local cache
        var updatedList = currentNodes
        updatedList.append(newNode)
        self.routineNodes[routineId] = updatedList
        
        // Update cached routine record
        for (studentId, list) in studentRoutines {
            if let idx = list.firstIndex(where: { $0.id == routineId }) {
                let old = list[idx]
                let updated = DBRoutineRow(
                    id: old.id,
                    name: old.name,
                    dance_name: old.dance_name,
                    dance_category: old.dance_category,
                    created_at: old.created_at,
                    updated_at: Date(),
                    last_modified_by: signature
                )
                var mutableList = list
                mutableList[idx] = updated
                self.studentRoutines[studentId] = mutableList
            }
        }
    }
    
    // MARK: - Update Node Coach Notes
    func updateNodeNotes(
        routineId: UUID,
        nodeId: UUID,
        coachNotes: String
    ) async throws {
        let client = SupabaseConfig.client
        
        struct NodeUpdateDTO: Encodable {
            let notes: String
        }
        
        try await client
            .from("canvas_nodes")
            .update(NodeUpdateDTO(notes: coachNotes))
            .eq("id", value: nodeId)
            .execute()
        
        let coachName = UserProfileStore.shared.currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let signature = coachName.isEmpty || coachName == "Tanečník" ? "Tréner" : "\(coachName) (Tréner)"
        
        struct RoutineUpdateDTO: Encodable {
            let last_modified_by: String
            let updated_at: String
        }
        
        let nowISO = ISO8601DateFormatter().string(from: Date())
        try await client
            .from("routines")
            .update(RoutineUpdateDTO(last_modified_by: signature, updated_at: nowISO))
            .eq("id", value: routineId)
            .execute()
        
        // Refresh local cache
        _ = await fetchRoutineNodes(routineId: routineId)
    }
}
