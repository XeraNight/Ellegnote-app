import SwiftUI
import SwiftData
import UIKit
import OSLog
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

// MARK: - Canvas Card Scale Mode
enum CanvasCardScaleMode: String, CaseIterable, Identifiable {
    case compact = "Kompakt (70%)"
    case normal  = "Štandard (100%)"
    case large   = "Detail (120%)"
    
    var id: String { rawValue }
    
    var scale: CGFloat {
        switch self {
        case .compact: return 0.72
        case .normal:  return 1.0
        case .large:   return 1.20
        }
    }
    
    var icon: String {
        switch self {
        case .compact: return "rectangle.compress.vertical"
        case .normal:  return "rectangle"
        case .large:   return "rectangle.expand.vertical"
        }
    }
    
    var next: CanvasCardScaleMode {
        switch self {
        case .compact: return .normal
        case .normal:  return .large
        case .large:   return .compact
        }
    }
}

struct RoutineCanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var routine: Routine
    
    private let canvasSize: CGFloat = 3000
    private let maxScale: CGFloat = 3.5
    
    // Framing & margins around ballroom floor for drawing annotations
    private var annotationMarginX: CGFloat { 48 }
    private var annotationMarginY: CGFloat { 64 }
    
    private var contentWidth: CGFloat {
        BallroomFloorConfig.floorWidth + 2 * annotationMarginX // 840 + 96 = 936 pt
    }
    private var contentHeight: CGFloat {
        BallroomFloorConfig.floorHeight + 2 * annotationMarginY // 1260 + 128 = 1388 pt
    }
    
    private func computedMinScale(for viewport: CGSize) -> CGFloat {
        let w = viewport.width > 0 ? viewport.width : (UIScreen.main.bounds.width > 0 ? UIScreen.main.bounds.width : 393)
        let h = viewport.height > 0 ? viewport.height : (UIScreen.main.bounds.height > 0 ? UIScreen.main.bounds.height : 852)
        let availableW = max(w - 24, 280)
        let availableH = max(h - (isPresentedInTab ? 200 : 130), 320)
        let fit = min(availableW / contentWidth, availableH / contentHeight)
        return max(fit, 0.35)
    }
    
    @State private var translation: CGSize = .zero
    @State private var scale: CGFloat = 0.42
    @State private var hasInitializedView: Bool = false
    @State private var viewportSize: CGSize = .zero
    @State private var activelyDraggedNodeIDs: Set<UUID> = []
    @State private var activePan: CGSize = .zero
    @State private var activeZoom: CGFloat = 1.0
    @State private var liveNodePositions: [UUID: CGPoint] = [:]
    
    // Card Customization States (Requested by User)
    @State private var cardScaleMode: CanvasCardScaleMode = .normal
    @State private var isFiguresTranslucent: Bool = false
    
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
    
    // Wireframe Actions & Sheets
    @State private var showActionsMenu = false
    @State private var showDuelSheet = false
    
    var isPresentedInTab: Bool = false
    var onBack: (() -> Void)? = nil
    
    @AppStorage("profileName") private var userName = "Tanečník"
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    
    init(routine: Routine, isPresentedInTab: Bool = false, onBack: (() -> Void)? = nil) {
        self.routine = routine
        self.isPresentedInTab = isPresentedInTab
        self.onBack = onBack
        let danceName = routine.danceName
        self._libraryItems = Query(filter: #Predicate<FigureLibraryItem> { $0.danceName == danceName })
    }
    
    var body: some View {
        let isStandard = routine.danceCategory.lowercased() == "standard"
        let accentColor = isStandard ? Color.standardBlue : Color.latinPink
        
        GeometryReader { geo in
            let viewport = geo.size.width > 0 ? geo.size : (UIScreen.main.bounds.size.width > 0 ? UIScreen.main.bounds.size : CGSize(width: 393, height: 852))
            let minScale = computedMinScale(for: viewport)
            let effectiveScale = min(max(scale * activeZoom, minScale), maxScale)
            
            ZStack {
                EllegancePageBackground()
                    .allowsHitTesting(false)
                
                // 1. Gesture Receiver Spanning Edge-to-Edge Viewport (1:1 Touch Tracking for Canvas Pan & Zoom)
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
                            viewportSize: viewport,
                            scale: effectiveScale
                        )
                        activePan = .zero
                    },
                    onPinchChanged: { zoomFactor in
                        guard !isDrawingMode else { return }
                        activeZoom = zoomFactor
                    },
                    onPinchEnded: { zoomFactor in
                        guard !isDrawingMode else { return }
                        let curMin = computedMinScale(for: viewport)
                        let clamped = min(max(scale * zoomFactor, curMin), maxScale)
                        scale = clamped
                        translation = clampedTranslation(
                            translation,
                            viewportSize: viewport,
                            scale: clamped
                        )
                        activeZoom = 1.0
                    }
                )
                .frame(width: viewport.width, height: viewport.height)
                
                // 2. Scaled Ballroom Canvas Layer (Strictly contained and clipped to Viewport)
                ZStack {
                    ZStack {
                        // 1. Ballroom Real Wood Parquet Floor (4 Planks Grid Squared in Canvas)
                        DanceParquetFloorView(roomSize: canvasSize)
                            .allowsHitTesting(false)
                        
                        // 2. Subtle Precision Grid over Parquet Floor
                        CanvasGridBackground(roomSize: canvasSize)
                            .opacity(0.12)
                            .allowsHitTesting(false)
                        
                        // 3. Golden Ballroom Markings & Long/Short Wall Indicators
                        BallroomMarkingsView(roomSize: canvasSize)
                            .allowsHitTesting(false)
                        
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
                            let lockedBy = realtimeManager.partnerPresences.values.first(where: { $0.draggingNodeId == node.id.uuidString })?.userName
                            CanvasNodeCardView(
                                node: node,
                                scale: effectiveScale,
                                cardScale: cardScaleMode.scale,
                                isTranslucent: isFiguresTranslucent,
                                lockedByUserName: lockedBy
                            ) {
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
                            .allowsHitTesting(false)
                        }
                    }
                    .frame(width: canvasSize, height: canvasSize)
                    .scaleEffect(effectiveScale, anchor: .center)
                    .offset(canvasOffset(in: viewport, scale: effectiveScale, pan: activePan))
                    
                    // Part 3 – Partner cursory (PresenceState z CanvasRealtimeManager)
                    ForEach(Array(realtimeManager.partnerPresences.values), id: \.userId) { presence in
                        PartnerCursorView(name: presence.userName, isDragging: presence.draggingNodeId != nil)
                            .position(
                                x: (presence.x - 1500) * effectiveScale + viewport.width / 2 + translation.width + activePan.width,
                                y: (presence.y - 1500) * effectiveScale + viewport.height / 2 + translation.height + activePan.height
                            )
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: viewport.width, height: viewport.height)
                .clipped()
                
                // ── 3. Floating Side Controls (Left: AirPlay + Pencil | Right: Refresh + Center) ──
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        // Left Side: Airplay Share & Pencil
                        VStack(spacing: 12) {
                            AirPlayPickerButton(size: 44)
                            
                            LiquidGlassCircleButton(
                                icon: isDrawingMode ? "pencil.line" : "pencil",
                                isActive: isDrawingMode,
                                activeColor: LuxuryTheme.latinCrimson,
                                size: 44,
                                iconSize: 17
                            ) {
                                isDrawingMode.toggle()
                            }
                            
                            if isDrawingMode && !sketchPaths.isEmpty {
                                LiquidGlassCircleButton(
                                    icon: "trash",
                                    size: 38,
                                    iconSize: 14,
                                    action: {
                                        withAnimation { sketchPaths.removeAll() }
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        Spacer()
                        
                        // Right Side: Hrubý Refresh & Vycentrovanie & Veľkosť Kariet & Priesvitnosť
                        VStack(spacing: 12) {
                            LiquidGlassCircleButton(
                                icon: "arrow.clockwise",
                                size: 44,
                                iconSize: 17,
                                isSpinning: isRefreshing
                            ) {
                                guard !isRefreshing else { return }
                                Task { await refreshFromDB(userInitiated: true) }
                            }
                            
                            LiquidGlassCircleButton(
                                icon: "scope",
                                size: 44,
                                iconSize: 17
                            ) {
                                fitAllNodes()
                            }
                            
                            // Prepínanie veľkosti kariet figúr (Kompakt 72% / Štandard 100% / Detail 120%)
                            LiquidGlassCircleButton(
                                icon: cardScaleMode.icon,
                                size: 44,
                                iconSize: 17
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    cardScaleMode = cardScaleMode.next
                                }
                                showToastNotification(message: "Veľkosť figúr: \(cardScaleMode.rawValue)")
                            }
                            
                            // Priesvitnosť / Liquid Glass (viditeľnosť parketu cez karty figúr)
                            LiquidGlassCircleButton(
                                icon: isFiguresTranslucent ? "square.2.layers.3d.top.filled" : "square.2.layers.3d",
                                isActive: isFiguresTranslucent,
                                activeColor: LuxuryTheme.gold400,
                                size: 44,
                                iconSize: 17
                            ) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isFiguresTranslucent.toggle()
                                }
                                showToastNotification(message: isFiguresTranslucent ? "Priesvitné karty (viditeľný parket)" : "Plné karty")
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, isPresentedInTab ? max(geo.safeAreaInsets.bottom + 92, 134) : max(geo.safeAreaInsets.bottom + 28, 50))
                }
                .frame(width: viewport.width, height: viewport.height)
                
                // ── 4. Floating Realtime Status Pill (Hovering Above Bottom Dock) ──
                VStack {
                    Spacer()
                    
                    RealtimeStatusPill(
                        isConnected: realtimeManager.isConnected,
                        isSyncing: isRefreshing
                    ) {
                        if !realtimeManager.isConnected {
                            realtimeManager.connect(to: routine.id, userName: userName)
                            Task { await refreshFromDB(userInitiated: true) }
                        }
                    }
                    .padding(.bottom, isPresentedInTab ? max(geo.safeAreaInsets.bottom + 78, 120) : max(geo.safeAreaInsets.bottom + 16, 36))
                }
                .frame(width: viewport.width, height: viewport.height)
                
                // ── 5. Top Floating Navigation Bar (Clean Single-Layer Liquid Glass, Pinned to Top) ──
                VStack {
                    HStack(alignment: .center) {
                        // Back Button (Single-Layer Liquid Glass Capsule)
                        Button {
                            if let onBack = onBack {
                                onBack()
                            } else {
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Späť")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    Capsule().fill(LuxuryTheme.obsidian800.opacity(0.70))
                                    Capsule().fill(.ultraThinMaterial)
                                }
                            )
                            .overlay(
                                Capsule().stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), LuxuryTheme.gold400.opacity(0.15), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Centered Dance Title & Routine Name
                        VStack(spacing: 2) {
                            Text(routine.name)
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(routine.danceName.uppercased())
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundColor(LuxuryTheme.gold400)
                                .tracking(1.2)
                        }
                        
                        Spacer()
                        
                        // Trailing: Single Clean Floating Liquid Glass Buttons (QR & Actions Menu)
                        HStack(spacing: 10) {
                            // Button 1: QR Code Zostavy
                            LiquidGlassCircleButton(
                                icon: "qrcode",
                                size: 40,
                                iconSize: 16
                            ) {
                                if let payload = QRGenerator.generatePayload(from: routine),
                                   let qrImg = QRGenerator.generateQRCode(from: payload) {
                                    self.qrCodeImage = qrImg
                                    self.showQRExport = true
                                }
                            }
                            
                            // Button 2: Actions Menu (...)
                            LiquidGlassCircleButton(
                                icon: "ellipsis",
                                size: 40,
                                iconSize: 16
                            ) {
                                showActionsMenu = true
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, max(geo.safeAreaInsets.top, 54))
                    
                    Spacer()
                }
                .frame(width: viewport.width, height: viewport.height)
                
                // Toast notification overlay
                if showToast, let msg = toastMessage {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(LuxuryTheme.gold400)
                            Text(msg)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                Capsule().fill(LuxuryTheme.obsidian800.opacity(0.85))
                                Capsule().fill(.ultraThinMaterial)
                            }
                        )
                        .overlay(Capsule().stroke(LuxuryTheme.gold400.opacity(0.35), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
                        .padding(.top, max(geo.safeAreaInsets.top, 54) + 48) // Floating under top bar
                        
                        Spacer()
                    }
                    .frame(width: viewport.width, height: viewport.height)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
            .frame(width: viewport.width, height: viewport.height)
            .onAppear {
                let initSize = geo.size.width > 0 ? geo.size : UIScreen.main.bounds.size
                viewportSize = initSize
                if !hasInitializedView {
                    hasInitializedView = true
                    fitBallroomFloor(in: initSize, animated: false)
                }
            }
            .onChange(of: geo.size) { oldSize, newSize in
                guard newSize.width > 0, newSize.height > 0 else { return }
                viewportSize = newSize
                if !hasInitializedView {
                    hasInitializedView = true
                    fitBallroomFloor(in: newSize, animated: false)
                } else if abs(oldSize.width - newSize.width) > 5 || abs(oldSize.height - newSize.height) > 5 {
                    translation = clampedTranslation(translation, viewportSize: newSize, scale: scale)
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)

        // ─────────────────────────────────────────────────────────────────
        // Part 2 – Auto-refresh po WebSocket reconnecte
        .onChange(of: realtimeManager.needsRefreshAfterReconnect) { _, needs in
            if needs {
                realtimeManager.needsRefreshAfterReconnect = false
                Task { await refreshFromDB() }
                showToastNotification(message: "Spojenie obnovené, sťahujú sa zmeny...")
            }
        }
        .sheet(isPresented: $showActionsMenu) {
            CanvasActionsMenuSheet(
                routineName: routine.name,
                onAddFigure: {
                    showFiguresDrawer = true
                },
                onDuelVideos: {
                    showDuelSheet = true
                },
                onOpenInventory: {
                    showRoutineVideoVault = true
                }
            )
        }
        .sheet(isPresented: $showDuelSheet) {
            NavigationStack {
                CompareHubView(
                    pathA: $routine.videoPath,
                    pathB: $routine.activeTargetVideoPath,
                    isPresented: $showDuelSheet
                )
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
            AppDelegate.orientationLock = .allButUpsideDown
            UIApplication.shared.isIdleTimerDisabled = true
            NavDepth.shared.push()   // hide floating dock while canvas is displayed for full screen ballroom view
            realtimeManager.connect(to: routine.id, userName: userName)
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
                            
                            // Replace nodes safely (never wipe local nodes with empty remote response)
                            if !dbNodes.isEmpty || routine.canvasNodes.isEmpty {
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
                            }
                            
                            try? modelContext.save()
                            Logger.canvas.info("Routine fully synchronized with remote DB.")
                        }
                    }
                }
            }
        }
        .onDisappear {
            AppDelegate.orientationLock = .portrait
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
            UIApplication.shared.isIdleTimerDisabled = false
            NavDepth.shared.pop()    // restore floating dock when leaving canvas
            realtimeManager.disconnect()
            stopLiveActivity()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && (oldPhase == .background || oldPhase == .inactive) {
                if !realtimeManager.isConnected {
                    realtimeManager.connect(to: routine.id, userName: userName)
                }
                Task {
                    await refreshFromDB(userInitiated: false)
                }
            }
        }
    }
    
    // MARK: - Manual DB Refresh (refresh button, no need to leave canvas)

    private func refreshFromDB(userInitiated: Bool = false) async {
        isRefreshing = true
        defer {
            Task { @MainActor in isRefreshing = false }
        }
        guard let (_, dbNodes) = await SupabaseSyncManager.shared.fetchRoutine(routine.id) else { return }

        await MainActor.run {
            // Reconcile nodes in place to avoid flickering or translation shift
            var existingMap = Dictionary(uniqueKeysWithValues: routine.canvasNodes.map { ($0.id, $0) })
            var newNodes: [CanvasNode] = []
            
            for dbNode in dbNodes {
                if let existing = existingMap.removeValue(forKey: dbNode.id) {
                    existing.figureName = dbNode.figure_name
                    existing.rhythm = dbNode.rhythm
                    existing.notes = dbNode.notes
                    existing.videoPath = dbNode.video_path
                    existing.orderIndex = dbNode.order_index
                    existing.transitionNotes = dbNode.transition_notes
                    if !activelyDraggedNodeIDs.contains(existing.id) {
                        existing.x = dbNode.x
                        existing.y = dbNode.y
                    }
                    newNodes.append(existing)
                } else {
                    let node = CanvasNode(
                        id: dbNode.id, x: dbNode.x, y: dbNode.y,
                        figureName: dbNode.figure_name, rhythm: dbNode.rhythm,
                        notes: dbNode.notes, videoPath: dbNode.video_path,
                        orderIndex: dbNode.order_index, transitionNotes: dbNode.transition_notes
                    )
                    node.routine = routine
                    modelContext.insert(node)
                    newNodes.append(node)
                }
            }
            
            for leftover in existingMap.values {
                modelContext.delete(leftover)
            }
            
            routine.canvasNodes = newNodes
            try? modelContext.save()
            if userInitiated {
                showToastNotification(message: "Zostava obnovená ✓")
            }
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
        let horizontalLimit = max(200.0, scaledCanvas / 2 + viewportSize.width / 2 - 120)
        let verticalLimit   = max(200.0, scaledCanvas / 2 + viewportSize.height / 2 - 120)
        return CGSize(
            width:  min(max(proposed.width,  -horizontalLimit), horizontalLimit),
            height: min(max(proposed.height, -verticalLimit),   verticalLimit)
        )
    }
    
    // MARK: - Canvas Actions
    
    private func addFigureToCanvas(_ item: FigureLibraryItem) {
        let sorted = routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        let nextIndex = sorted.count
        
        // Compute safe spawn bounds strictly within the parquet floor
        let cardW = 140.0 * cardScaleMode.scale
        let cardH = 132.0 * cardScaleMode.scale
        let bounds = BallroomFloorConfig.safeCardBounds(
            cardWidth: cardW,
            cardHeight: cardH,
            wallMargin: 20
        )
        
        let cols = 3
        let col = nextIndex % cols
        let row = (nextIndex / cols) % 5
        let stepX = (bounds.maxX - bounds.minX) / CGFloat(max(cols - 1, 1))
        let stepY = min(150.0, (bounds.maxY - bounds.minY) / 5.0)
        
        let spawnX = min(max(bounds.minX + CGFloat(col) * stepX, bounds.minX), bounds.maxX)
        let spawnY = min(max(bounds.minY + CGFloat(row) * stepY, bounds.minY), bounds.maxY)
        
        let node = CanvasNode(
            x: Double(spawnX),
            y: Double(spawnY),
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
    
    /// Fits the entire ballroom floor within the user's viewport with comfortable padding,
    /// ensuring the full wooden floor, golden outer border, and left/right wall markings are immediately visible.
    private func fitBallroomFloor(in viewport: CGSize, animated: Bool = true) {
        guard viewport.width > 0, viewport.height > 0 else { return }
        let targetScale = computedMinScale(for: viewport)
        
        if animated {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                scale = targetScale
                translation = .zero
            }
        } else {
            scale = targetScale
            translation = .zero
        }
    }
    
    private func fitAllNodes() {
        let nodes = routine.canvasNodes
        guard !nodes.isEmpty else {
            fitBallroomFloor(in: viewportSize)
            return
        }
        
        let minS = computedMinScale(for: viewportSize)
        
        // Include node bounds as well as ballroom center anchor
        let xs = nodes.map { $0.x } + [BallroomFloorConfig.centerPoint.x - BallroomFloorConfig.floorWidth * 0.40, BallroomFloorConfig.centerPoint.x + BallroomFloorConfig.floorWidth * 0.40]
        let ys = nodes.map { $0.y } + [BallroomFloorConfig.centerPoint.y - BallroomFloorConfig.floorHeight * 0.40, BallroomFloorConfig.centerPoint.y + BallroomFloorConfig.floorHeight * 0.40]
        let minX = xs.min() ?? 1150.0, maxX = xs.max() ?? 1850.0
        let minY = ys.min() ?? 950.0,  maxY = ys.max() ?? 2050.0
        let centerX = (minX + maxX) / 2.0
        let centerY = (minY + maxY) / 2.0
        let boundsWidth  = max(maxX - minX + 60, contentWidth)
        let boundsHeight = max(maxY - minY + 60, contentHeight)
        let availableWidth  = max(viewportSize.width  - 24,  280)
        let availableHeight = max(viewportSize.height - (isPresentedInTab ? 200 : 130), 320)
        let targetScale = min(max(min(availableWidth / boundsWidth, availableHeight / boundsHeight), minS), maxScale)
        
        withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
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
        
        let attributes = EncoreAttributes(
            routineName: routine.name,
            danceName: routine.danceName
        )
        
        let sortedNodes = routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
        let currentName = sortedNodes.first?.figureName ?? "Spustenie zostavy"
        let nextName = sortedNodes.count > 1 ? sortedNodes[1].figureName : ""
        
        let initialState = EncoreAttributes.ContentState(
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
        
        let updatedState = EncoreAttributes.ContentState(
            currentFigureName: currentName,
            nextFigureName: nextName,
            currentFigureIndex: index + 1,
            totalFigures: sortedNodes.count,
            lastUpdated: Date()
        )
        
        Task {
            for activity in Activity<EncoreAttributes>.activities {
                if activity.attributes.routineName == routine.name {
                    await activity.update(.init(state: updatedState, staleDate: nil))
                }
            }
        }
    }
    
    private func stopLiveActivity() {
        Task {
            for activity in Activity<EncoreAttributes>.activities {
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
