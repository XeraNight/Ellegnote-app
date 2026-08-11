import Foundation
import Supabase
import Combine

struct DBFigureRow: Codable {
    let id: UUID
    let name: String
    let dance_name: String
    let rhythm: String
    let technique_notes: String
    let image_path: String?
    let video_path: String?
    let is_custom: Bool
}

struct DBRoutineRow: Codable {
    let id: UUID
    let name: String
    let dance_name: String
    let dance_category: String
    let created_at: Date
    let updated_at: Date
    let last_modified_by: String?
}

struct DBCanvasNodeRow: Codable {
    let id: UUID
    let routine_id: UUID
    let x: Double
    let y: Double
    let figure_name: String
    let rhythm: String
    let notes: String
    let video_path: String?
    let order_index: Int
    let transition_notes: String
}

@globalActor
actor SyncActor {
    static let shared = SyncActor()
}

private actor RoutineSyncDebouncer {
    private var tasks: [UUID: Task<Void, Never>] = [:]
    
    func schedule(routineId: UUID, delay: Duration = .milliseconds(700), operation: @escaping @Sendable () async -> Void) {
        tasks[routineId]?.cancel()
        tasks[routineId] = Task(priority: .background) { [weak self] in
            do {
                try await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                await operation()
                await self?.clear(routineId)
            } catch {
                await self?.clear(routineId)
            }
        }
    }
    
    private func clear(_ routineId: UUID) {
        tasks[routineId] = nil
    }
}

final class SupabaseSyncManager: Sendable {
    static let shared = SupabaseSyncManager()
    
    private let client: SupabaseClient?
    private let routineSyncDebouncer = RoutineSyncDebouncer()
    
    private init() {
        if let url = SupabaseConfig.url, let anonKey = SupabaseConfig.anonKey {
            self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        } else {
            self.client = nil
        }
    }
    
    var isEnabled: Bool {
        client != nil
    }
    
    // MARK: - Database Synchronisation
    
    @SyncActor
    func syncFigure(_ figureId: UUID, name: String, danceName: String, rhythm: String, notes: String, imagePath: String?, videoPath: String?, isCustom: Bool) async {
        guard let client else { return }
        
        let row = DBFigureRow(
            id: figureId,
            name: name,
            dance_name: danceName,
            rhythm: rhythm,
            technique_notes: notes,
            image_path: imagePath,
            video_path: videoPath,
            is_custom: isCustom
        )
        
        do {
            try await client
                .from("figure_library_items")
                .upsert(row)
                .execute()
            print("Successfully synced figure \(name) to Supabase Database.")
        } catch {
            print("Failed to sync figure \(name) to Supabase Database: \(error)")
        }
    }
    
    @SyncActor
    func deleteFigure(_ figureId: UUID) async {
        guard let client else { return }
        
        do {
            try await client
                .from("figure_library_items")
                .delete()
                .eq("id", value: figureId)
                .execute()
            print("Successfully deleted figure \(figureId) from Supabase Database.")
        } catch {
            print("Failed to delete figure \(figureId) from Supabase Database: \(error)")
        }
    }
    
    @SyncActor
    func syncRoutine(_ routineId: UUID, name: String, danceName: String, category: String, createdAt: Date, updatedAt: Date, lastModifiedBy: String?, nodes: [DBCanvasNodeRow]) async {
        guard let client else { return }
        
        let routineRow = DBRoutineRow(
            id: routineId,
            name: name,
            dance_name: danceName,
            dance_category: category,
            created_at: createdAt,
            updated_at: updatedAt,
            last_modified_by: lastModifiedBy
        )
        
        do {
            // 1. Upsert Routine (create or update)
            try await client
                .from("routines")
                .upsert(routineRow)
                .execute()
            
            if nodes.isEmpty {
                // 2a. No nodes – delete everything for this routine
                try await client
                    .from("canvas_nodes")
                    .delete()
                    .eq("routine_id", value: routineId)
                    .execute()
            } else {
                // 2b. Upsert all nodes – UPDATE existing, INSERT new ones
                // onConflict: "id" = ak node už existuje, updatuje; inak vytvorí
                try await client
                    .from("canvas_nodes")
                    .upsert(nodes, onConflict: "id")
                    .execute()
                
                // 3. Vymaž osirotené nodes (existujú v DB ale nie lokálne)
                // Toto nespustí false DELETE eventy pre existujúce figury
                let ids = nodes.map { $0.id.uuidString.lowercased() }
                let idsString = ids.joined(separator: ",")
                try await client
                    .from("canvas_nodes")
                    .delete()
                    .eq("routine_id", value: routineId)
                    .not("id", operator: .in, value: "(\(idsString))")
                    .execute()
            }
            
            print("Successfully synced routine \(name) and \(nodes.count) nodes to Supabase Database.")
        } catch {
            print("Failed to sync routine \(name) to Supabase Database: \(error)")
        }
    }
    
    @SyncActor
    func fetchRoutine(_ routineId: UUID) async -> (DBRoutineRow, [DBCanvasNodeRow])? {
        guard let client else { return nil }
        
        do {
            let routineRow: DBRoutineRow = try await client
                .from("routines")
                .select()
                .eq("id", value: routineId)
                .single()
                .execute()
                .value
            
            let nodes: [DBCanvasNodeRow] = try await client
                .from("canvas_nodes")
                .select()
                .eq("routine_id", value: routineId)
                .execute()
                .value
            
            return (routineRow, nodes)
        } catch {
            print("Failed to fetch routine \(routineId) from Supabase: \(error)")
            return nil
        }
    }
    
    @SyncActor
    func deleteRoutine(_ routineId: UUID) async {
        guard let client else { return }
        
        do {
            try await client
                .from("routines")
                .delete()
                .eq("id", value: routineId)
                .execute()
            print("Successfully deleted routine \(routineId) from Supabase Database.")
        } catch {
            print("Failed to delete routine \(routineId) from Supabase Database: \(error)")
        }
    }
    
    func syncRoutineOnBackground(_ routine: Routine) {
        guard isEnabled else { return }
        
        let routineId = routine.id
        let name = routine.name
        let danceName = routine.danceName
        let category = routine.danceCategory
        let createdAt = routine.createdAt
        let updatedAt = routine.updatedAt
        let lastModifiedBy = routine.lastModifiedBy
        
        // Map nodes to Codable rows
        let nodesRows = routine.canvasNodes.map { node in
            DBCanvasNodeRow(
                id: node.id,
                routine_id: routineId,
                x: node.x,
                y: node.y,
                figure_name: node.figureName,
                rhythm: node.rhythm,
                notes: node.notes,
                video_path: node.videoPath,
                order_index: node.orderIndex,
                transition_notes: node.transitionNotes
            )
        }
        
        Task(priority: .background) {
            await self.routineSyncDebouncer.schedule(routineId: routineId) {
                await self.syncRoutine(
                    routineId,
                    name: name,
                    danceName: danceName,
                    category: category,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    lastModifiedBy: lastModifiedBy,
                    nodes: nodesRows
                )
            }
        }
    }
    
    func syncRoutineImmediatelyOnBackground(_ routine: Routine) {
        guard isEnabled else { return }
        
        let routineId = routine.id
        let name = routine.name
        let danceName = routine.danceName
        let category = routine.danceCategory
        let createdAt = routine.createdAt
        let updatedAt = routine.updatedAt
        let lastModifiedBy = routine.lastModifiedBy
        let nodesRows = routine.canvasNodes.map { node in
            DBCanvasNodeRow(
                id: node.id,
                routine_id: routineId,
                x: node.x,
                y: node.y,
                figure_name: node.figureName,
                rhythm: node.rhythm,
                notes: node.notes,
                video_path: node.videoPath,
                order_index: node.orderIndex,
                transition_notes: node.transitionNotes
            )
        }
        
        Task(priority: .background) {
            await self.syncRoutine(
                routineId,
                name: name,
                danceName: danceName,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastModifiedBy: lastModifiedBy,
                nodes: nodesRows
            )
        }
    }
    
    // MARK: - File Storage Upload
    
    @SyncActor
    @discardableResult
    func uploadFileAsync(localFileName: String, bucket: String = "ellegnote-media") async -> URL? {
        guard let client else { return nil }
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(localFileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("File does not exist on disk: \(fileURL.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let fileExtension = fileURL.pathExtension.lowercased()
            let contentType: String
            
            if fileExtension == "mp4" || fileExtension == "mov" {
                contentType = "video/mp4"
            } else if fileExtension == "jpg" || fileExtension == "jpeg" {
                contentType = "image/jpeg"
            } else if fileExtension == "png" {
                contentType = "image/png"
            } else {
                contentType = "application/octet-stream"
            }
            
            let remotePath = localFileName
            print("Uploading file to Supabase Storage: \(remotePath) (size: \(data.count) bytes)")
            
            // Upload to Supabase Storage (using options to specify content-type)
            try await client.storage
                .from(bucket)
                .upload(
                    path: remotePath,
                    file: data,
                    options: FileOptions(contentType: contentType, upsert: true)
                )
            
            let publicURL = try client.storage
                .from(bucket)
                .getPublicURL(path: remotePath)
            
            print("Successfully uploaded \(localFileName) to Supabase Storage: \(publicURL)")
            return publicURL
        } catch {
            print("Failed to upload \(localFileName) to Supabase Storage: \(error)")
            return nil
        }
    }
}
