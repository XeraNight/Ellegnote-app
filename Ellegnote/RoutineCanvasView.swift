import SwiftUI
import SwiftData
import UIKit
import OSLog
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
    @State private var showPDFExport = false
    @State private var qrCodeImage: UIImage? = nil
    @State private var showRoutineVideoVault = false
    @State private var isCanvasLocked = false
    
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
                                guard !isCanvasLocked else { return }
                                liveNodePositions[node.id] = CGPoint(x: liveX, y: liveY)
                                realtimeManager.broadcastNodeMove(nodeId: node.id, x: liveX, y: liveY)
                                realtimeManager.updatePresence(x: liveX, y: liveY, userName: userName, draggingNodeId: node.id)
                            } onDragStart: {
                                guard !isCanvasLocked else { return }
                                activelyDraggedNodeIDs.insert(node.id)
                            } onDragEnd: { finalX, finalY in
                                guard !isCanvasLocked else { return }
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
                        
                        if routine.canvasNodes.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "figure.dance")
                                    .font(.system(size: 48))
                                    .foregroundColor(accentColor.opacity(0.8))
                                Text("Prázdny tanečný parket")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.themeDark)
                                Text("Ťukni na 'Pridať figúru' a naplánuj choreografiu.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.themeTextSecondary)
                            }
                            .padding(20)
                            .background(Color.themeCard.opacity(0.95))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.themeDark.opacity(0.15), lineWidth: 1.5))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
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
                    
                    Button(action: {
                        isCanvasLocked.toggle()
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        showToastNotification(message: isCanvasLocked ? "🔒 Plátno zamknuté proti nechceným dotykom" : "🔓 Plátno odomknuté")
                    }) {
                        Image(systemName: isCanvasLocked ? "lock.fill" : "lock.open")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isCanvasLocked ? .white : .themeDark)
                            .padding(14)
                    }
                    .buttonStyle(.neubrutalistToggle(isActive: isCanvasLocked, activeColor: Color.amberGold, cornerRadius: 24))
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
                HStack(spacing: 8) {
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

                    // S2-4 — Sync failure badge (visible only when cloud sync failed)
                    if SupabaseSyncManager.syncStatus.isFailure {
                        Label("Offline", systemImage: "icloud.slash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.orange.opacity(0.12))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        showRoutineVideoVault = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "film.stack")
                            Text("Videá")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.themeAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.themeAccent.opacity(0.12))
                        .cornerRadius(6)
                    }

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
                        self.showPDFExport = true
                    } label: {
                        Image(systemName: "doc.text.fill")
                    }

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
        .sheet(isPresented: $showRoutineVideoVault) {
            VideoVaultView(
                routine: routine,
                activeSlotAPath: $routine.videoPath,
                activeSlotBPath: $routine.activeTargetVideoPath
            )
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
        .sheet(isPresented: $showPDFExport) {
            RoutinePDFPreviewSheet(routine: routine)
        }
        .sheet(isPresented: $showQRExport) {
            QRExportSheet(routine: routine, qrImage: qrCodeImage)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
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
                            Logger.canvas.info("Routine fully synchronized with remote DB.")
                        }
                    }
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
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
            Logger.camera.info("Live Activity started.")
        } catch {
            Logger.camera.error("Live Activity start failed: \(error.localizedDescription, privacy: .public)")
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
