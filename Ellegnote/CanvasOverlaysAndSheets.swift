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
