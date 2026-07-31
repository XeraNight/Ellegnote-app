import Foundation
import Supabase
import Observation

struct DragMessage: Codable, Sendable {
    let nodeId: UUID
    let x: Double
    let y: Double
    let senderId: UUID?
    
    init(nodeId: UUID, x: Double, y: Double, senderId: UUID? = nil) {
        self.nodeId = nodeId
        self.x = x
        self.y = y
        self.senderId = senderId
    }
}

struct CanvasActionMessage: Codable, Sendable {
    let action: String          // "added", "deleted", "updated", "transition_updated"
    let nodeId: UUID
    let figureName: String
    let x: Double
    let y: Double
    let rhythm: String
    let notes: String
    let videoPath: String?
    let orderIndex: Int
    let transitionNotes: String
    let senderId: UUID
    let senderName: String
}

// MARK: - Presence (Part 3 – partner cursory)
struct PresenceState: Codable, Sendable {
    let userId: String        // senderId.uuidString
    let userName: String
    let x: Double
    let y: Double
    let draggingNodeId: String?  // nil = len pohyb kurzora, inak ťahá figúrku
}

@Observable
final class CanvasRealtimeManager {
    private let client: SupabaseClient?
    private var channel: RealtimeChannelV2?
    private let senderId = UUID()
    private var lastBroadcastAtByNode: [UUID: Date] = [:]
    private let minimumBroadcastInterval: TimeInterval = 0.04
    private var listenerTasks: [Task<Void, Never>] = []

    var isConnected = false
    var isRefreshing = false
    var needsRefreshAfterReconnect = false  // Part 2 – trigger auto-refresh po reconnecte

    // MARK: - Presence (Part 3)
    var partnerPresences: [String: PresenceState] = [:]  // userId → stav

    // MARK: - Broadcast Callbacks (low-latency drag & canvas actions)
    var onNodeMoved: ((UUID, Double, Double) -> Void)?
    var onNodeAdded: ((CanvasNode, String) -> Void)?
    var onNodeDeleted: ((UUID, String, String) -> Void)?
    var onNodeUpdated: ((CanvasNode, String) -> Void)?
    var onTransitionUpdated: ((UUID, String, String) -> Void)?

    // MARK: - Postgres Change Callbacks (DB-level sync fallback)
    var onDBNodeInserted: ((DBCanvasNodeRow) -> Void)?
    var onDBNodeUpdated: ((DBCanvasNodeRow) -> Void)?
    var onDBNodeDeleted: ((UUID) -> Void)?

    init() {
        if let url = SupabaseConfig.url, let anonKey = SupabaseConfig.anonKey {
            self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        } else {
            self.client = nil
        }
    }

    func connect(to routineId: UUID) {
        guard let client else {
            print("Supabase Realtime disabled: missing SUPABASE_URL or SUPABASE_ANON_KEY.")
            return
        }
        
        let channelId = "canvas_\(routineId.uuidString.lowercased())"
        print("Connecting to Supabase Realtime Channel: \(channelId)")

        Task {
            let ch = client.realtimeV2.channel(channelId)

            // MARK: Broadcast – node drag (low latency, no DB)
            _ = ch.onBroadcast(event: "node_moved") { [weak self] payload in
                guard let self else { return }
                Task { @MainActor in
                    guard let jsonData = try? JSONEncoder().encode(payload),
                          let drag = try? JSONDecoder().decode(DragMessage.self, from: jsonData) else {
                        return
                    }
                    guard drag.senderId != self.senderId else { return }
                    self.onNodeMoved?(drag.nodeId, drag.x, drag.y)
                }
            }

            // MARK: Broadcast – canvas structural actions
            _ = ch.onBroadcast(event: "canvas_action") { [weak self] payload in
                guard let self else { return }
                Task { @MainActor in
                    guard let jsonData = try? JSONEncoder().encode(payload),
                          let actionMsg = try? JSONDecoder().decode(CanvasActionMessage.self, from: jsonData) else {
                        return
                    }
                    guard actionMsg.senderId != self.senderId else { return }
                    
                    if actionMsg.action == "added" {
                        let node = CanvasNode(
                            id: actionMsg.nodeId,
                            x: actionMsg.x,
                            y: actionMsg.y,
                            figureName: actionMsg.figureName,
                            rhythm: actionMsg.rhythm,
                            notes: actionMsg.notes,
                            videoPath: actionMsg.videoPath,
                            orderIndex: actionMsg.orderIndex,
                            transitionNotes: actionMsg.transitionNotes
                        )
                        self.onNodeAdded?(node, actionMsg.senderName)
                    } else if actionMsg.action == "deleted" {
                        self.onNodeDeleted?(actionMsg.nodeId, actionMsg.figureName, actionMsg.senderName)
                    } else if actionMsg.action == "updated" {
                        let node = CanvasNode(
                            id: actionMsg.nodeId,
                            x: actionMsg.x,
                            y: actionMsg.y,
                            figureName: actionMsg.figureName,
                            rhythm: actionMsg.rhythm,
                            notes: actionMsg.notes,
                            videoPath: actionMsg.videoPath,
                            orderIndex: actionMsg.orderIndex,
                            transitionNotes: actionMsg.transitionNotes
                        )
                        self.onNodeUpdated?(node, actionMsg.senderName)
                    } else if actionMsg.action == "transition_updated" {
                        self.onTransitionUpdated?(actionMsg.nodeId, actionMsg.transitionNotes, actionMsg.senderName)
                    }
                }
            }

            // MARK: Postgres Changes – DB-level fallback (upsert nevyvolá false DELETE eventy)
            // Requires: ALTER PUBLICATION supabase_realtime ADD TABLE canvas_nodes;
            // Requires: ALTER TABLE canvas_nodes REPLICA IDENTITY FULL;
            let pgFilter = "routine_id=eq.\(routineId.uuidString.lowercased())"
            let insertions = ch.postgresChange(InsertAction.self, schema: "public", table: "canvas_nodes", filter: pgFilter)
            let updates    = ch.postgresChange(UpdateAction.self, schema: "public", table: "canvas_nodes", filter: pgFilter)
            let deletions  = ch.postgresChange(DeleteAction.self, schema: "public", table: "canvas_nodes", filter: pgFilter)

            // MARK: Presence – partner cursory (Part 3)
            let presenceChanges = ch.presenceChange()

            do {
                try await ch.subscribeWithError()
            } catch {
                print("Failed to subscribe to Supabase Realtime: \(error)")
                return
            }

            self.channel = ch
            await MainActor.run {
                self.isConnected = true
                print("Successfully subscribed to Supabase Realtime: \(channelId)")
            }

            // Track our own presence
            let myPresence = PresenceState(
                userId: senderId.uuidString,
                userName: "User",
                x: 0, y: 0,
                draggingNodeId: nil
            )
            try? await ch.track(myPresence)

            // Helper decoder shared across tasks
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys

            // Postgres Change streams – no more suppress needed (upsert nespôsobí false DELETE)
            let t1 = Task { [weak self] in
                guard let self else { return }
                for await insert in insertions {
                    if let data = try? JSONEncoder().encode(insert.record),
                       let row = try? decoder.decode(DBCanvasNodeRow.self, from: data) {
                        await MainActor.run { self.onDBNodeInserted?(row) }
                    }
                }
            }
            let t2 = Task { [weak self] in
                guard let self else { return }
                for await update in updates {
                    if let data = try? JSONEncoder().encode(update.record),
                       let row = try? decoder.decode(DBCanvasNodeRow.self, from: data) {
                        await MainActor.run { self.onDBNodeUpdated?(row) }
                    }
                }
            }
            let t3 = Task { [weak self] in
                guard let self else { return }
                for await deletion in deletions {
                    // Needs REPLICA IDENTITY FULL to get the old record's ID
                    if let data = try? JSONEncoder().encode(deletion.oldRecord),
                       let row = try? decoder.decode(DBCanvasNodeRow.self, from: data) {
                        await MainActor.run { self.onDBNodeDeleted?(row.id) }
                    }
                }
            }

            // Presence stream – partner cursory (Part 3)
            let t4 = Task { [weak self] in
                guard let self else { return }
                for await presenceChange in presenceChanges {
                    var newPresences: [String: PresenceState] = [:]
                    // Zostavíme celý stav zo joins (Supabase posiela full state)
                    for (_, presence) in presenceChange.joins {
                        if let data = try? JSONEncoder().encode(presence.state),
                           let state = try? decoder.decode(PresenceState.self, from: data) {
                            newPresences[state.userId] = state
                        }
                    }
                    // Zachováme existujúce presences okrem tých čo odišli
                    let leaveKeys = Set(presenceChange.leaves.keys)
                    await MainActor.run {
                        var updated = self.partnerPresences.merging(newPresences) { _, new in new }
                        for key in leaveKeys { updated.removeValue(forKey: key) }
                        // Nezobrazujeme vlastný kurzor
                        updated.removeValue(forKey: self.senderId.uuidString)
                        self.partnerPresences = updated
                    }
                }
            }

            self.listenerTasks = [t1, t2, t3, t4]

            // MARK: Part 2 – Heartbeat: sleduje stav kanála každých 8 sekúnd
            let heartbeat = Task { [weak self] in
                var wasConnected = true
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(8))
                    guard let self, let ch = self.channel else { continue }
                    // RealtimeChannelV2.status je synchronná property
                    let alive = await ch.status == .subscribed
                    await MainActor.run {
                        if alive && !wasConnected {
                            // Práve sa obnovilo spojenie
                            self.isConnected = true
                            self.needsRefreshAfterReconnect = true
                            print("Supabase Realtime reconnected – triggering auto-refresh")
                        } else if !alive {
                            self.isConnected = false
                        }
                        wasConnected = alive
                    }
                }
            }
            self.listenerTasks.append(heartbeat)
        }
    }

    // MARK: - Presence Update (volaj pri každom pohybe / drag)
    func updatePresence(x: Double, y: Double, userName: String, draggingNodeId: UUID? = nil) {
        guard let ch = channel, isConnected else { return }
        let state = PresenceState(
            userId: senderId.uuidString,
            userName: userName,
            x: x, y: y,
            draggingNodeId: draggingNodeId?.uuidString
        )
        Task { try? await ch.track(state) }
    }

    // MARK: - Broadcast Senders

    func broadcastNodeMove(nodeId: UUID, x: Double, y: Double, force: Bool = false) {
        guard let ch = channel, isConnected else { return }
        
        if !force {
            let now = Date()
            if let last = lastBroadcastAtByNode[nodeId],
               now.timeIntervalSince(last) < minimumBroadcastInterval {
                return
            }
            lastBroadcastAtByNode[nodeId] = now
        }
        
        let message = DragMessage(nodeId: nodeId, x: x, y: y, senderId: senderId)
        Task { try? await ch.broadcast(event: "node_moved", message: message) }
    }

    func broadcastNodeAdded(node: CanvasNode, senderName: String) {
        guard let ch = channel, isConnected else { return }
        let message = CanvasActionMessage(action: "added", nodeId: node.id, figureName: node.figureName,
            x: node.x, y: node.y, rhythm: node.rhythm, notes: node.notes, videoPath: node.videoPath,
            orderIndex: node.orderIndex, transitionNotes: node.transitionNotes, senderId: senderId, senderName: senderName)
        Task { try? await ch.broadcast(event: "canvas_action", message: message) }
    }

    func broadcastNodeDeleted(nodeId: UUID, figureName: String, senderName: String) {
        guard let ch = channel, isConnected else { return }
        let message = CanvasActionMessage(action: "deleted", nodeId: nodeId, figureName: figureName,
            x: 0, y: 0, rhythm: "", notes: "", videoPath: nil, orderIndex: 0, transitionNotes: "",
            senderId: senderId, senderName: senderName)
        Task { try? await ch.broadcast(event: "canvas_action", message: message) }
    }

    func broadcastNodeUpdated(node: CanvasNode, senderName: String) {
        guard let ch = channel, isConnected else { return }
        let message = CanvasActionMessage(action: "updated", nodeId: node.id, figureName: node.figureName,
            x: node.x, y: node.y, rhythm: node.rhythm, notes: node.notes, videoPath: node.videoPath,
            orderIndex: node.orderIndex, transitionNotes: node.transitionNotes, senderId: senderId, senderName: senderName)
        Task { try? await ch.broadcast(event: "canvas_action", message: message) }
    }

    func broadcastTransitionUpdated(node: CanvasNode, senderName: String) {
        guard let ch = channel, isConnected else { return }
        let message = CanvasActionMessage(action: "transition_updated", nodeId: node.id, figureName: node.figureName,
            x: node.x, y: node.y, rhythm: node.rhythm, notes: node.notes, videoPath: node.videoPath,
            orderIndex: node.orderIndex, transitionNotes: node.transitionNotes, senderId: senderId, senderName: senderName)
        Task { try? await ch.broadcast(event: "canvas_action", message: message) }
    }

    // MARK: - Disconnect

    func disconnect() {
        for task in listenerTasks { task.cancel() }
        listenerTasks = []
        partnerPresences = [:]
        guard let client, let ch = channel else { return }
        Task {
            try? await ch.untrack()
            await client.realtimeV2.removeChannel(ch)
        }
        channel = nil
        isConnected = false
        print("Disconnected from Supabase Realtime")
    }
}
