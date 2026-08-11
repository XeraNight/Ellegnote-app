import SwiftUI
import SwiftData
import UIKit
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

struct RoutineCanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var routine: Routine
    
    private let canvasSize: CGFloat = 3000
    private let minScale: CGFloat = 0.55
    private let maxScale: CGFloat = 2.5
    
    @State private var translation: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var viewportSize: CGSize = .zero
    @State private var activelyDraggedNodeIDs: Set<UUID> = []
    @State private var activePan: CGSize = .zero
    @State private var activeZoom: CGFloat = 1.0
    @State private var liveNodePositions: [UUID: CGPoint] = [:]
    
    @State private var showFiguresDrawer = false
    @State private var selectedNodeForEdit: CanvasNode?
    @State private var selectedConnectionForEdit: CanvasConnection?
    
    @Query private var libraryItems: [FigureLibraryItem]
    
    @State private var realtimeManager = CanvasRealtimeManager()
    @State private var isRefreshing = false
    @State private var sketchPaths: [Path] = []
    @State private var currentPath = Path()
    @State private var isDrawingMode = false
    @State private var showQRExport = false
    @State private var qrCodeImage: UIImage? = nil
    
    @AppStorage("profileName") private var userName = "Tanečník"
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    
    init(routine: Routine) {
        self.routine = routine
        let danceName = routine.danceName
        self._libraryItems = Query(filter: #Predicate<FigureLibraryItem> { $0.danceName == danceName })
    }
    
    var body: some View {
        let isStandard = routine.danceCategory.lowercased() == "standard"
        let accentColor = isStandard ? Color.standardBlue : Color.latinPink
        let effectiveScale = min(max(scale * activeZoom, minScale), maxScale)
        
        ZStack {
            Color.themeBg.ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {

                    ZStack {
                        CanvasGestureView(
                            onPanChanged: { delta in
                                guard !isDrawingMode else { return }
                                guard activelyDraggedNodeIDs.isEmpty else { return }
                                activePan = delta
                            },
                            onPanEnded: { delta in
                                guard !isDrawingMode else { return }
                                guard activelyDraggedNodeIDs.isEmpty else { return }
                                translation = clampedTranslation(
                                    CGSize(
                                        width: translation.width + delta.width,
                                        height: translation.height + delta.height
                                    ),
                                    viewportSize: geo.size,
                                    scale: scale
                                )
                                activePan = .zero
                            },
                            onPinchChanged: { zoomFactor in
                                guard !isDrawingMode else { return }
                                activeZoom = zoomFactor
                            },
                            onPinchEnded: { zoomFactor in
                                guard !isDrawingMode else { return }
                                let clamped = min(max(scale * zoomFactor, minScale), maxScale)
                                let ratio = clamped / scale
                                scale = clamped
                                translation = clampedTranslation(
                                    CGSize(
                                        width: translation.width * ratio,
                                        height: translation.height * ratio
                                    ),
                                    viewportSize: geo.size,
                                    scale: clamped
                                )
                                activeZoom = 1.0
                            }
                        )
                        
                        CanvasGridBackground(roomSize: canvasSize)
                            .opacity(0.4)
                        
                        BallroomMarkingsView(roomSize: canvasSize)
                        
                        if isDrawingMode {
                            DrawingCanvas(paths: $sketchPaths, currentPath: $currentPath)
                                .frame(width: canvasSize, height: canvasSize)
                        }
                        
                        ConnectionsLayer(
                            nodes: routine.canvasNodes,
                            livePositions: liveNodePositions
                        ) { prevNode, nextNode in
                            selectedConnectionForEdit = CanvasConnection(from: prevNode, to: nextNode)
                        }
                        
                        ForEach(routine.canvasNodes) { node in
                            CanvasNodeCardView(node: node, scale: effectiveScale) {
                                selectedNodeForEdit = node
                                updateLiveActivity(with: node)
                            } onDelete: {
                                deleteNode(node)
                            } onDrag: { liveX, liveY in
                                liveNodePositions[node.id] = CGPoint(x: liveX, y: liveY)
                                realtimeManager.broadcastNodeMove(nodeId: node.id, x: liveX, y: liveY)
                                realtimeManager.updatePresence(x: liveX, y: liveY, userName: userName, draggingNodeId: node.id)
                            } onDragStart: {
                                activelyDraggedNodeIDs.insert(node.id)
                            } onDragEnd: { finalX, finalY in
                                activelyDraggedNodeIDs.remove(node.id)
                                liveNodePositions.removeValue(forKey: node.id)
                                routine.updatedAt = Date()
                                routine.lastModifiedBy = userName
                                try? modelContext.save()
                                SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                                realtimeManager.broadcastNodeMove(nodeId: node.id, x: finalX, y: finalY, force: true)
                                realtimeManager.updatePresence(x: finalX, y: finalY, userName: userName, draggingNodeId: nil)
                            }
                        }
                    }
                    .frame(width: canvasSize, height: canvasSize)
                    .scaleEffect(effectiveScale, anchor: .center)
                    .offset(canvasOffset(in: geo.size, scale: effectiveScale, pan: activePan))
                    
                    // Part 3 – Partner cursory (PresenceState z CanvasRealtimeManager)
                    ForEach(Array(realtimeManager.partnerPresences.values), id: \.userId) { presence in
                        PartnerCursorView(name: presence.userName, isDragging: presence.draggingNodeId != nil)
                            .position(
                                x: (presence.x - 1500) * effectiveScale + geo.size.width / 2 + translation.width + activePan.width,
                                y: (presence.y - 1500) * effectiveScale + geo.size.height / 2 + translation.height + activePan.height
                            )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .onAppear { viewportSize = geo.size }
                .onChange(of: geo.size) { _, newSize in
                    viewportSize = newSize
                    translation = clampedTranslation(translation, viewportSize: newSize, scale: scale)
                }
            }
            
            // Minimap overlay
            VStack {
                HStack {
                    Spacer()
                    MinimapView(nodes: routine.canvasNodes, scale: scale)
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                }
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Floating UI controls
            VStack {
                Spacer()
                
                if let author = routine.lastModifiedBy {
                    Text("Naposledy upravil: \(author)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.themeDark.opacity(0.45))
                        .padding(.bottom, 4)
                }
                
                if realtimeManager.isConnected {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Realtime pripojené")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.themeDark)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .neubrutalistCard(cornerRadius: 20, shadowOffset: 2)
                    .padding(.bottom, 8)
                }
                
                HStack(spacing: 12) {
                    Button(action: { showFiguresDrawer = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Pridať figúru")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.neubrutalist(accentColor: accentColor, cornerRadius: 24))
                    
                    Button(action: { isDrawingMode.toggle() }) {
                        Image(systemName: isDrawingMode ? "pencil.line" : "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isDrawingMode ? .white : .themeDark)
                            .padding(14)
                    }
                    .buttonStyle(.neubrutalistToggle(isActive: isDrawingMode, activeColor: Color.latinRed, cornerRadius: 24))
                    
                    if !sketchPaths.isEmpty {
                        Button(action: { sketchPaths.removeAll() }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.latinRed)
                                .padding(14)
                        }
                        .buttonStyle(.neubrutalistSecondary(cornerRadius: 24))
                    }
                    
                    Button(action: fitAllNodes) {
                        Image(systemName: "scope")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.themeDark)
                            .padding(14)
                    }
                    .buttonStyle(.neubrutalistSecondary(cornerRadius: 24))
                }
                .padding(.bottom, 28)  // above home indicator; dock is hidden on canvas
            }
            
            // Toast notification overlay
            if showToast, let msg = toastMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.themeAccent)
                        Text(msg)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.themeDark)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .neubrutalistCard(cornerRadius: 12, shadowOffset: 2)
                    .padding(.top, 56) // Floating under transparent status bar
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        // ── Swipe-back fix ───────────────────────────────────────────────
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("Späť")
                    }
                    .foregroundColor(.themeDark)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        Task { await refreshFromDB() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing
                                    ? .linear(duration: 0.7).repeatForever(autoreverses: false)
                                    : .default,
                                value: isRefreshing
                            )
                    }
                    .disabled(isRefreshing)

                    Button {
                        if let payload = QRGenerator.generatePayload(from: routine),
                           let qrImg = QRGenerator.generateQRCode(from: payload) {
                            self.qrCodeImage = qrImg
                            self.showQRExport = true
                        }
                    } label: {
                        Image(systemName: "qrcode")
                    }
                }
            }
        }
        // ─────────────────────────────────────────────────────────────────
        // Part 2 – Auto-refresh po WebSocket reconnecte
        .onChange(of: realtimeManager.needsRefreshAfterReconnect) { _, needs in
            if needs {
                realtimeManager.needsRefreshAfterReconnect = false
                Task { await refreshFromDB() }
                showToastNotification(message: "Spojenie obnovené, sťahujú sa zmeny...")
            }
        }
        .sheet(isPresented: $showFiguresDrawer) {
            FiguresDrawerSheet(
                isPresented: $showFiguresDrawer,
                danceName: routine.danceName,
                libraryItems: libraryItems
            ) { selectedItem in
                addFigureToCanvas(selectedItem)
                showFiguresDrawer = false
            }
        }
        .sheet(item: $selectedNodeForEdit) { node in
            FigureDetailCard(node: node, realtimeManager: realtimeManager)
        }
        .sheet(item: $selectedConnectionForEdit) { conn in
            TransitionEditSheet(fromNode: conn.from, toNode: conn.to, realtimeManager: realtimeManager) {
                selectedConnectionForEdit = nil
            }
        }
        .sheet(isPresented: $showQRExport) {
            QRExportSheet(routine: routine, qrImage: qrCodeImage)
        }
        .onAppear {
            NavDepth.shared.push()   // hide floating dock while canvas is shown
            realtimeManager.connect(to: routine.id)
            startLiveActivity()
            
            // 1. Move Node Realtime Handler
            realtimeManager.onNodeMoved = { nodeId, x, y in
                guard !activelyDraggedNodeIDs.contains(nodeId) else { return }
                if let node = routine.canvasNodes.first(where: { $0.id == nodeId }) {
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.82)) {
                        node.x = x
                        node.y = y
                    }
                    try? modelContext.save()
                }
            }
            
            // 2. Add Node Realtime Handler
            realtimeManager.onNodeAdded = { node, senderName in
                if !routine.canvasNodes.contains(where: { $0.id == node.id }) {
                    node.routine = routine
                    modelContext.insert(node)
                    try? modelContext.save()
                    showToastNotification(message: "\(senderName) pridal figúru \(node.figureName)")
                }
            }
            
            // 3. Delete Node Realtime Handler
            realtimeManager.onNodeDeleted = { nodeId, figureName, senderName in
                if let node = routine.canvasNodes.first(where: { $0.id == nodeId }) {
                    modelContext.delete(node)
                    try? modelContext.save()
                    showToastNotification(message: "\(senderName) vymazal figúru \(figureName)")
                }
            }
            
            // 3b. Update Node Realtime Handler
            realtimeManager.onNodeUpdated = { updatedNode, senderName in
                if let node = routine.canvasNodes.first(where: { $0.id == updatedNode.id }) {
                    node.notes = updatedNode.notes
                    node.videoPath = updatedNode.videoPath
                    try? modelContext.save()
                    showToastNotification(message: "\(senderName) upravil detaily \(node.figureName)")
                }
            }
            
            // 3c. Update Transition Realtime Handler
            realtimeManager.onTransitionUpdated = { nodeId, transitionNotes, senderName in
                if let node = routine.canvasNodes.first(where: { $0.id == nodeId }) {
                    node.transitionNotes = transitionNotes
                    try? modelContext.save()
                    showToastNotification(message: "\(senderName) upravil prechod")
                }
            }

            // 4a. Postgres Changes – INSERT (záloha ak broadcast chýba, idempotentný)
            realtimeManager.onDBNodeInserted = { row in
                // Broadcast príde ~50ms, Postgres Change ~200-500ms – guard zabraňuje duplikátu
                guard !routine.canvasNodes.contains(where: { $0.id == row.id }) else { return }
                let node = CanvasNode(
                    id: row.id, x: row.x, y: row.y,
                    figureName: row.figure_name, rhythm: row.rhythm,
                    notes: row.notes, videoPath: row.video_path,
                    orderIndex: row.order_index, transitionNotes: row.transition_notes
                )
                node.routine = routine
                modelContext.insert(node)
                try? modelContext.save()
            }

            // 4b. Postgres Changes – UPDATE (aktualizuje polia existujúceho nodu)
            realtimeManager.onDBNodeUpdated = { row in
                guard !activelyDraggedNodeIDs.contains(row.id) else { return }
                guard let node = routine.canvasNodes.first(where: { $0.id == row.id }) else { return }
                node.x = row.x
                node.y = row.y
                node.notes = row.notes
                node.videoPath = row.video_path
                node.transitionNotes = row.transition_notes
                node.orderIndex = row.order_index
                try? modelContext.save()
            }

            // 4c. Postgres Changes – DELETE (vyžaduje REPLICA IDENTITY FULL v Supabase)
            realtimeManager.onDBNodeDeleted = { nodeId in
                guard let node = routine.canvasNodes.first(where: { $0.id == nodeId }) else { return }
                modelContext.delete(node)
                try? modelContext.save()
            }

            // 5. Initial Sync with Supabase Database on connection
            Task {
                if let (dbRoutine, dbNodes) = await SupabaseSyncManager.shared.fetchRoutine(routine.id) {
                    // Check if DB version is newer
                    if dbRoutine.updated_at > routine.updatedAt {
                        await MainActor.run {
                            routine.name = dbRoutine.name
                            routine.danceName = dbRoutine.dance_name
                            routine.danceCategory = dbRoutine.dance_category
                            routine.updatedAt = dbRoutine.updated_at
                            routine.lastModifiedBy = dbRoutine.last_modified_by
                            
                            // Replace nodes
                            for node in routine.canvasNodes {
                                modelContext.delete(node)
                            }
                            routine.canvasNodes.removeAll()
                            
                            for dbNode in dbNodes {
                                let node = CanvasNode(
                                    id: dbNode.id,
                                    x: dbNode.x,
                                    y: dbNode.y,
                                    figureName: dbNode.figure_name,
                                    rhythm: dbNode.rhythm,
                                    notes: dbNode.notes,
                                    videoPath: dbNode.video_path,
                                    orderIndex: dbNode.order_index,
                                    transitionNotes: dbNode.transition_notes
                                )
                                node.routine = routine
                                modelContext.insert(node)
                            }
                            
                            try? modelContext.save()
                            print("Routine fully synchronized with Supabase Database.")
                        }
                    }
                }
            }
        }
        .onDisappear {
            NavDepth.shared.pop()    // restore floating dock on nav pop
            realtimeManager.disconnect()
            stopLiveActivity()
        }
    }
    
    // MARK: - Manual DB Refresh (refresh button, no need to leave canvas)

    private func refreshFromDB() async {
        isRefreshing = true
        defer {
            Task { @MainActor in isRefreshing = false }
        }
        guard let (_, dbNodes) = await SupabaseSyncManager.shared.fetchRoutine(routine.id) else { return }

        await MainActor.run {
            // Replace all nodes with latest from DB
            for node in routine.canvasNodes { modelContext.delete(node) }
            routine.canvasNodes.removeAll()
            for dbNode in dbNodes {
                let node = CanvasNode(
                    id: dbNode.id, x: dbNode.x, y: dbNode.y,
                    figureName: dbNode.figure_name, rhythm: dbNode.rhythm,
                    notes: dbNode.notes, videoPath: dbNode.video_path,
                    orderIndex: dbNode.order_index, transitionNotes: dbNode.transition_notes
                )
                node.routine = routine
                modelContext.insert(node)
            }
            try? modelContext.save()
            showToastNotification(message: "Zostava obnovená ✓")
        }
    }

    private func showToastNotification(message: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation {
            toastMessage = message
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showToast = false
            }
        }
    }
    
    // MARK: - Canvas Math
    
    private func canvasOffset(in viewportSize: CGSize, scale: CGFloat, pan: CGSize) -> CGSize {
        return clampedTranslation(
            CGSize(
                width: translation.width + pan.width,
                height: translation.height + pan.height
            ),
            viewportSize: viewportSize,
            scale: scale
        )
    }
    
    private func clampedTranslation(_ proposed: CGSize, viewportSize: CGSize, scale: CGFloat) -> CGSize {
        guard viewportSize.width > 0, viewportSize.height > 0 else { return proposed }
        let scaledCanvas = canvasSize * scale
        let horizontalLimit = max(100.0, scaledCanvas / 2 + viewportSize.width / 2 - 100)
        let verticalLimit   = max(100.0, scaledCanvas / 2 + viewportSize.height / 2 - 100)
        return CGSize(
            width:  min(max(proposed.width,  -horizontalLimit), horizontalLimit),
            height: min(max(proposed.height, -verticalLimit),   verticalLimit)
        )
    }
    
    // MARK: - Canvas Actions
    
    private func addFigureToCanvas(_ item: FigureLibraryItem) {
        let sorted = routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        let nextIndex = sorted.count
        let col = nextIndex % 4
        let row = nextIndex / 4
        let node = CanvasNode(
            x: 1500.0 + Double(col * 240),
            y: 1500.0 + Double(row * 180),
            figureName: item.name,
            rhythm: item.rhythm,
            notes: item.techniqueNotes,
            orderIndex: nextIndex
        )
        routine.canvasNodes.append(node)
        routine.updatedAt = Date()
        routine.lastModifiedBy = userName
        try? modelContext.save()
        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
        realtimeManager.broadcastNodeAdded(node: node, senderName: userName)
    }
    
    private func deleteNode(_ node: CanvasNode) {
        let nodeId = node.id
        let figureName = node.figureName
        
        if let videoPath = node.videoPath {
            MediaStorageManager.removeFile(named: videoPath)
        }
        modelContext.delete(node)
        let sorted = routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        for i in 0..<sorted.count { sorted[i].orderIndex = i }
        routine.updatedAt = Date()
        routine.lastModifiedBy = userName
        try? modelContext.save()
        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
        realtimeManager.broadcastNodeDeleted(nodeId: nodeId, figureName: figureName, senderName: userName)
    }
    
    private func fitAllNodes() {
        let nodes = routine.canvasNodes
        guard !nodes.isEmpty else {
            withAnimation(.spring()) { translation = .zero; scale = 1.0 }
            return
        }
        let xs = nodes.map { $0.x }
        let ys = nodes.map { $0.y }
        let minX = xs.min() ?? 1500.0, maxX = xs.max() ?? 1500.0
        let minY = ys.min() ?? 1500.0, maxY = ys.max() ?? 1500.0
        let centerX = (minX + maxX) / 2.0
        let centerY = (minY + maxY) / 2.0
        let boundsWidth  = max(maxX - minX + 360, 600)
        let boundsHeight = max(maxY - minY + 320, 500)
        let availableWidth  = max(viewportSize.width  - 48,  320)
        let availableHeight = max(viewportSize.height - 180, 320)
        let targetScale = min(max(min(availableWidth / boundsWidth, availableHeight / boundsHeight), minScale), 1.15)
        withAnimation(.spring()) {
            scale = targetScale
            translation = clampedTranslation(
                CGSize(
                    width:  CGFloat(1500.0 - centerX) * targetScale,
                    height: CGFloat(1500.0 - centerY) * targetScale
                ),
                viewportSize: viewportSize,
                scale: targetScale
            )
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Live Activity Management
    
    #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        stopLiveActivity()
        
        let attributes = EllegnoteAttributes(
            routineName: routine.name,
            danceName: routine.danceName
        )
        
        let sortedNodes = routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        let currentName = sortedNodes.first?.figureName ?? "Spustenie zostavy"
        let nextName = sortedNodes.count > 1 ? sortedNodes[1].figureName : ""
        
        let initialState = EllegnoteAttributes.ContentState(
            currentFigureName: currentName,
            nextFigureName: nextName,
            currentFigureIndex: sortedNodes.isEmpty ? 0 : 1,
            totalFigures: sortedNodes.count,
            lastUpdated: Date()
        )
        
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("Live Activity started successfully.")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivity(with node: CanvasNode) {
        let sortedNodes = routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        guard let index = sortedNodes.firstIndex(where: { $0.id == node.id }) else { return }
        
        let currentName = node.figureName
        let nextName = (index + 1 < sortedNodes.count) ? sortedNodes[index + 1].figureName : ""
        
        let updatedState = EllegnoteAttributes.ContentState(
            currentFigureName: currentName,
            nextFigureName: nextName,
            currentFigureIndex: index + 1,
            totalFigures: sortedNodes.count,
            lastUpdated: Date()
        )
        
        Task {
            for activity in Activity<EllegnoteAttributes>.activities {
                if activity.attributes.routineName == routine.name {
                    await activity.update(.init(state: updatedState, staleDate: nil))
                }
            }
        }
    }
    
    private func stopLiveActivity() {
        Task {
            for activity in Activity<EllegnoteAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    #else
    private func startLiveActivity() {}
    private func updateLiveActivity(with node: CanvasNode) {}
    private func stopLiveActivity() {}
    #endif
}

// MARK: - Canvas Grid Background
struct CanvasGridBackground: View {
    let roomSize: CGFloat
    var body: some View {
        Path { path in
            let step: CGFloat = 80
            for x in stride(from: 0, to: roomSize, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: roomSize))
            }
            for y in stride(from: 0, to: roomSize, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: roomSize, y: y))
            }
        }
        .stroke(Color.themeBorder.opacity(0.6), lineWidth: 1)
        .drawingGroup()
    }
}

// MARK: - Ballroom Markings
struct BallroomMarkingsView: View {
    let roomSize: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.themeDark.opacity(0.06), lineWidth: 5)
                .frame(width: roomSize - 160, height: roomSize - 160)
            Circle()
                .stroke(Color.themeDark.opacity(0.08), lineWidth: 2)
                .frame(width: 200, height: 200)
            Text("STRED SÁLY\n(Center of Room)")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.themeDark.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Connections Layer
struct ConnectionsLayer: View {
    let nodes: [CanvasNode]
    var livePositions: [UUID: CGPoint] = [:]
    var onConnectionTap: (CanvasNode, CanvasNode) -> Void
    
    private func pos(for node: CanvasNode) -> CGPoint {
        livePositions[node.id] ?? CGPoint(x: node.x, y: node.y)
    }
    
    var body: some View {
        let sorted = nodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        ZStack {
            ForEach(0..<sorted.count, id: \.self) { idx in
                if idx > 0 {
                    let prev = sorted[idx - 1]
                    let curr = sorted[idx]
                    let p1 = pos(for: prev)
                    let p2 = pos(for: curr)
                    
                    ConnectionLineShape(from: p1, to: p2)
                        .stroke(
                            LinearGradient(
                                colors: [Color.themeAccent.opacity(0.5), Color.themeAccent.opacity(0.2)],
                                startPoint: .init(x: 0, y: 0),
                                endPoint: .init(x: 1, y: 1)
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4])
                        )
                    
                    let centerPoint = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                    Button(action: { onConnectionTap(prev, curr) }) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.themeAccent)
                                .background(Color.themeCard.clipShape(Circle()))
                            if !curr.transitionNotes.isEmpty {
                                Text(curr.transitionNotes)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.themeAccent)
                                    .cornerRadius(6)
                                    .shadow(color: Color.themeDark.opacity(0.05), radius: 2)
                            }
                        }
                    }
                    .position(centerPoint)
                }
            }
        }
    }
}

struct ConnectionLineShape: Shape {
    var from: CGPoint
    var to: CGPoint
    
    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { AnimatablePair(from.animatableData, to.animatableData) }
        set { from.animatableData = newValue.first; to.animatableData = newValue.second }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let dx = to.x - from.x
        path.addCurve(
            to: to,
            control1: CGPoint(x: from.x + dx * 0.5, y: from.y),
            control2: CGPoint(x: from.x + dx * 0.5, y: to.y)
        )
        return path
    }
}

// MARK: - Canvas Node Card View
struct CanvasNodeCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var node: CanvasNode
    let scale: CGFloat
    var onTap: () -> Void
    var onDelete: () -> Void
    var onDrag: ((Double, Double) -> Void)? = nil
    var onDragStart: (() -> Void)? = nil
    var onDragEnd: ((Double, Double) -> Void)? = nil
    
    @State private var dragOffset: CGSize = .zero
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("#\(node.orderIndex + 1)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.themeAccent)
                    .cornerRadius(6)
                Spacer()
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "multiply")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.themeDark.opacity(0.4))
                }
            }
            Text(node.figureName)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(.themeDark)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if !node.rhythm.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.rhythm)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.themeAccent)
                    
                    BeatsTimelineView(rhythm: node.rhythm)
                }
            }
            HStack(spacing: 6) {
                if node.videoPath != nil {
                    Image(systemName: "video.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.themeAccent)
                }
                if !node.notes.isEmpty {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.themeDark.opacity(0.5))
                }
            }
        }
        .padding(12)
        .frame(width: 140, height: 132)
        .neubrutalistCard(cornerRadius: 16, shadowOffset: 3)
        .position(x: node.x + dragOffset.width, y: node.y + dragOffset.height)
        .confirmationDialog("Vymazať túto figúru zo zostavy?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Vymazať", role: .destructive) { onDelete() }
            Button("Zrušiť", role: .cancel) {}
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    if dragOffset == .zero { onDragStart?() }
                    dragOffset = CGSize(
                        width:  value.translation.width  / scale,
                        height: value.translation.height / scale
                    )
                    onDrag?(node.x + dragOffset.width, node.y + dragOffset.height)
                }
                .onEnded { value in
                    let finalX = node.x + value.translation.width  / scale
                    let finalY = node.y + value.translation.height / scale
                    node.x = finalX
                    node.y = finalY
                    dragOffset = .zero
                    try? modelContext.save()
                    if let routine = node.routine {
                        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                    }
                    onDragEnd?(finalX, finalY)
                }
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Minimap Overlay
struct MinimapView: View {
    let nodes: [CanvasNode]
    let scale: CGFloat
    var body: some View {
        let size = 110.0
        let miniRatio = size / 3000.0
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.themeCard.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.themeDark, lineWidth: 2)
                )
                .frame(width: size, height: size)
                .shadow(color: Color.themeDark, radius: 0, x: 3, y: 3)
            ForEach(nodes) { node in
                let clampedX = min(max(CGFloat(node.x), 0), 3000)
                let clampedY = min(max(CGFloat(node.y), 0), 3000)
                Circle()
                    .fill(Color.themeAccent)
                    .frame(width: 6, height: 6)
                    .position(x: clampedX * miniRatio, y: clampedY * miniRatio)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Figures Drawer Sheet
struct FiguresDrawerSheet: View {
    @Binding var isPresented: Bool
    let danceName: String
    let libraryItems: [FigureLibraryItem]
    var onSelectFigure: (FigureLibraryItem) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dostupné figúry pre \(danceName)")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                        LazyVStack(spacing: 8) {
                            ForEach(libraryItems) { item in
                                Button(action: { onSelectFigure(item) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(.system(size: 15, weight: .bold, design: .serif))
                                                .foregroundColor(.themeDark)
                                            Text(item.rhythm)
                                                .font(.system(size: 12))
                                                .foregroundColor(.themeAccent)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.themeAccent)
                                    }
                                    .padding()
                                    .neubrutalistCard(cornerRadius: 12, shadowOffset: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Pridať figúru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { isPresented = false }
                        .foregroundColor(.themeDark)
                }
            }
        }
    }
}

// MARK: - Transition Edit Sheet
struct TransitionEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let fromNode: CanvasNode
    let toNode: CanvasNode
    let realtimeManager: CanvasRealtimeManager?
    var onSave: () -> Void
    
    @AppStorage("profileName") private var userName = "Tanečník"
    @State private var notesText = ""
    @State private var autoSaveTask: Task<Void, Never>? = nil
    @State private var isAutoSaved = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prechod zo:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        Text(fromNode.figureName)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                        Text("do:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        Text(toNode.figureName)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .neubrutalistCard(cornerRadius: 14, shadowOffset: 3)
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Poznámka k prechodu (spoju)")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                            .padding(.horizontal, 20)
                        TextEditor(text: $notesText)
                            .scrollContentBackground(.hidden)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.themeCard)
                            .foregroundColor(.themeDark)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeDark, lineWidth: 2))
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        toNode.transitionNotes = notesText
                        try? modelContext.save()
                        if let routine = toNode.routine {
                            routine.updatedAt = Date()
                            routine.lastModifiedBy = userName
                            try? routine.modelContext?.save()
                            SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                        }
                        realtimeManager?.broadcastTransitionUpdated(node: toNode, senderName: userName)
                        onSave()
                    }) {
                        Text("Hotovo")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.neubrutalist(accentColor: Color.themeAccent))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Poznámka prechodu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.themeBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .onAppear {
                notesText = toNode.transitionNotes
            }
            .onChange(of: notesText) { _, newText in
                autoSaveTask?.cancel()
                autoSaveTask = Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    guard !Task.isCancelled else { return }
                    
                    toNode.transitionNotes = newText
                    try? modelContext.save()
                    realtimeManager?.broadcastTransitionUpdated(node: toNode, senderName: userName)
                    
                    if let routine = toNode.routine {
                        routine.updatedAt = Date()
                        routine.lastModifiedBy = userName
                        try? routine.modelContext?.save()
                        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
                    }
                    await MainActor.run {
                        withAnimation { isAutoSaved = true }
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        withAnimation { isAutoSaved = false }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { onSave() }
                        .foregroundColor(.themeDark)
                }
                ToolbarItem(placement: .primaryAction) {
                    if isAutoSaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.cloud.fill")
                                .foregroundColor(.themeAccent)
                            Text("Uložené")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.themeDark)
                        }
                        .transition(.opacity)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") { UIApplication.shared.endEditing() }
                        .foregroundColor(.themeAccent)
                }
            }
            .onAppear { notesText = toNode.transitionNotes }
        }
    }
}

// MARK: - Canvas Connection Model
struct CanvasConnection: Identifiable {
    let from: CanvasNode
    let to: CanvasNode
    var id: String { "\(from.id.uuidString)-\(to.id.uuidString)" }
}

// MARK: - UIKit Canvas Gesture View
// Handles pan + pinch natively to avoid SwiftUI gesture conflicts.
// Swipe-back is disabled via .navigationBarBackButtonHidden(true) on
// RoutineCanvasView — no UIKit gesture hacks needed here.
struct CanvasGestureView: UIViewRepresentable {
    var onPanChanged: (CGSize) -> Void
    var onPanEnded: (CGSize) -> Void
    var onPinchChanged: (CGFloat) -> Void
    var onPinchEnded: (CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 2
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        view.addGestureRecognizer(pinch)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onPanChanged = onPanChanged
        context.coordinator.onPanEnded = onPanEnded
        context.coordinator.onPinchChanged = onPinchChanged
        context.coordinator.onPinchEnded = onPinchEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onPanChanged: onPanChanged,
            onPanEnded: onPanEnded,
            onPinchChanged: onPinchChanged,
            onPinchEnded: onPinchEnded
        )
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPanChanged: (CGSize) -> Void
        var onPanEnded: (CGSize) -> Void
        var onPinchChanged: (CGFloat) -> Void
        var onPinchEnded: (CGFloat) -> Void

        init(
            onPanChanged: @escaping (CGSize) -> Void,
            onPanEnded: @escaping (CGSize) -> Void,
            onPinchChanged: @escaping (CGFloat) -> Void,
            onPinchEnded: @escaping (CGFloat) -> Void
        ) {
            self.onPanChanged = onPanChanged
            self.onPanEnded = onPanEnded
            self.onPinchChanged = onPinchChanged
            self.onPinchEnded = onPinchEnded
        }

        @objc func handlePan(_ gr: UIPanGestureRecognizer) {
            guard gr.numberOfTouches <= 2 else { return }
            let t = gr.translation(in: gr.view)
            let delta = CGSize(width: t.x, height: t.y)
            switch gr.state {
            case .changed:           onPanChanged(delta)
            case .ended, .cancelled: onPanEnded(delta)
            default: break
            }
        }

        @objc func handlePinch(_ gr: UIPinchGestureRecognizer) {
            switch gr.state {
            case .changed:           onPinchChanged(gr.scale)
            case .ended, .cancelled: onPinchEnded(gr.scale)
            default: break
            }
        }

        func gestureRecognizer(_ gr: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
        func gestureRecognizer(_ gr: UIGestureRecognizer, shouldRequireFailureOf other: UIGestureRecognizer) -> Bool { false }
    }
}

// MARK: - Drawing Canvas
struct DrawingCanvas: View {
    @Binding var paths: [Path]
    @Binding var currentPath: Path
    
    var body: some View {
        Canvas { context, size in
            for path in paths {
                context.stroke(
                    path,
                    with: .color(Color.latinRed),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
            }
            context.stroke(
                currentPath,
                with: .color(Color.latinRed),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
        }
        .background(Color.black.opacity(0.001))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = value.location
                    if currentPath.isEmpty {
                        currentPath.move(to: point)
                    } else {
                        currentPath.addLine(to: point)
                    }
                }
                .onEnded { _ in
                    if !currentPath.isEmpty {
                        paths.append(currentPath)
                        currentPath = Path()
                    }
                }
        )
    }
}

// MARK: - QR Export Sheet
struct QRExportSheet: View {
    let routine: Routine
    let qrImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Zdieľanie zostavy")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(.themeDark)
                        .padding(.top, 24)
                    
                    Text("Naskenuj QR kód na druhom zariadení alebo skopíruj textový kód pre prenos na Mac/PC.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.themeDark.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    if let img = qrImage {
                        Image(uiImage: img)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.themeDark, lineWidth: 3)
                            )
                            .shadow(color: Color.themeDark, radius: 0, x: 4, y: 4)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Generovanie QR kódu...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 220, height: 220)
                    }
                    
                    Text(routine.name.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.themeAccent)
                        .tracking(1.5)
                    
                    Button(action: {
                        if let payload = QRGenerator.generatePayload(from: routine) {
                            UIPasteboard.general.string = payload
                            withAnimation { copiedToClipboard = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedToClipboard = false
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                            Text(copiedToClipboard ? "Kód skopírovaný!" : "Kopírovať textový kód")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.neubrutalistSecondary(cornerRadius: 12))
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Text("Zavrieť")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.neubrutalist(accentColor: Color.themeDark))
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") {
                        dismiss()
                    }
                    .foregroundColor(.themeDark)
                }
            }
        }
    }
}

// MARK: - Beats Timeline View
struct BeatsTimelineView: View {
    let rhythm: String
    
    var beats: [String] {
        rhythm.components(separatedBy: CharacterSet(charactersIn: ", ")).filter { !$0.isEmpty }
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<beats.count, id: \.self) { index in
                let token = beats[index]
                let isAnd = token.lowercased() == "a"
                
                if isAnd {
                    Text("&")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.themeAccent)
                } else {
                    let label = token.first?.uppercased() ?? ""
                    Text(label)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.themeDark)
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Partner Cursor View (Presence)
struct PartnerCursorView: View {
    let name: String
    let isDragging: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isDragging ? "hand.draw.fill" : "arrow.up.left.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isDragging ? Color.orange : Color.themeAccent)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}
