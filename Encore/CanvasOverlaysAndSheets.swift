import SwiftUI
import SwiftData
import UIKit

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
                        .stroke(Color.gold400.opacity(0.25), lineWidth: 1)
                )
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 3)
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
                Color.obsidian800.ignoresSafeArea()
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
                                .background(Color.themeCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold400.opacity(0.18), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
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
                        .foregroundColor(.gold400)
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
                Color.obsidian800.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prechod zo:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeTextSecondary)
                        Text(fromNode.figureName)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                        Text("do:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeTextSecondary)
                            .padding(.top, 8)
                        Text(toNode.figureName)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.themeDark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.themeCard)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold400.opacity(0.20), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 3)
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
                        saveNow()
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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                    Button("Zavrieť") {
                        saveNow()
                        onSave()
                    }
                        .foregroundColor(.gold400)
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
            .onDisappear {
                saveNow()
            }
        }
    }
    
    private func saveNow() {
        autoSaveTask?.cancel()
        autoSaveTask = nil
        
        guard toNode.transitionNotes != notesText else { return }
        toNode.transitionNotes = notesText
        try? modelContext.save()
        realtimeManager?.broadcastTransitionUpdated(node: toNode, senderName: userName)
        
        if let routine = toNode.routine {
            routine.updatedAt = Date()
            routine.lastModifiedBy = userName
            try? routine.modelContext?.save()
            SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
        }
    }
}

// MARK: - UIKit Canvas Gesture View
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
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
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
            guard gr.numberOfTouches <= 1 else { return }
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

        func gestureRecognizer(_ gr: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            if (gr is UIPanGestureRecognizer && other is UIPinchGestureRecognizer) ||
               (gr is UIPinchGestureRecognizer && other is UIPanGestureRecognizer) {
                return false
            }
            return true
        }
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
/// Shares a routine as a QR code or a text code. The code is made here, off the main thread, so the
/// share button always opens this sheet at once, even when the routine is too big for a QR code.
struct QRExportSheet: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss

    private enum QRState {
        case loading
        case ready(UIImage)
        case tooLarge
    }

    @State private var state: QRState = .loading
    @State private var payload: String?
    @State private var copyCount = 0
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text(routine.name)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text(routine.danceName.uppercased())
                                .font(.system(.caption, design: .rounded).weight(.black))
                                .foregroundColor(Color.gold400)
                                .tracking(1.4)
                        }
                        .padding(.top, 8)

                        qrCard

                        Text(explanation)
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        PrimarySheetButton(
                            title: showCopied ? "Skopírované" : "Kopírovať textový kód",
                            isLoading: false,
                            isEnabled: payload != nil,
                            action: copy
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Zdieľať zostavu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { dismiss() }
                }
            }
            .task { await build() }
            .task(id: copyCount) {
                guard copyCount > 0 else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showCopied = true }
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 0.3)) { showCopied = false }
            }
            .sensoryFeedback(.success, trigger: copyCount)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var qrCard: some View {
        ZStack {
            switch state {
            case .loading:
                ProgressView()
                    .tint(Color.gold400)
            case .ready(let image):
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .accessibilityLabel("QR kód zostavy \(routine.name)")
            case .tooLarge:
                VStack(spacing: 10) {
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundColor(Color.gold400)
                    Text("Zostava je na QR kód príliš veľká")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .transition(.opacity)
            }
        }
        .frame(width: 250, height: 250)
        .homeCard(cornerRadius: 22)
    }

    private var explanation: String {
        switch state {
        case .tooLarge:
            return "Pošli ju ako textový kód: skopíruj ho a na druhom iPhone ho vlož cez QR tlačidlo na Domove."
        default:
            return "Naskenuj QR kód na druhom iPhone, alebo skopíruj textový kód a pošli ho správou."
        }
    }

    private func build() async {
        guard let text = QRGenerator.generatePayload(from: routine) else {
            state = .tooLarge
            return
        }
        payload = text
        let image = await Task.detached(priority: .userInitiated) {
            QRGenerator.generateQRCode(from: text)
        }.value
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            state = image.map(QRState.ready) ?? .tooLarge
        }
    }

    private func copy() {
        guard let payload else { return }
        UIPasteboard.general.string = payload
        copyCount += 1
    }
}
