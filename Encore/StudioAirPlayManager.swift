import SwiftUI
import AVKit
import Combine

// MARK: - AirPlay Route Picker Representable
struct AirPlayRoutePickerRepresentable: UIViewRepresentable {
    var tintColor: UIColor = .white
    var activeTintColor: UIColor = UIColor(Color.amberGold)
    
    init(tintColor: UIColor = .white, activeTintColor: UIColor = UIColor(Color.amberGold)) {
        self.tintColor = tintColor
        self.activeTintColor = activeTintColor
    }
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = tintColor
        picker.activeTintColor = activeTintColor
        picker.prioritizesVideoDevices = true
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
        uiView.activeTintColor = activeTintColor
    }
}

// MARK: - Studio AirPlay Manager
final class StudioAirPlayManager: ObservableObject {
    static let shared = StudioAirPlayManager()
    
    @Published var isExternalScreenConnected: Bool = false
    @Published var externalScreenName: String = "Žiadna TV"
    
    private let routeDetector = AVRouteDetector()
    private var externalWindow: UIWindow? = nil
    
    private init() {
        routeDetector.isRouteDetectionEnabled = true
        setupSceneObservers()
        checkExistingScenes()
    }
    
    private func setupSceneObservers() {
        NotificationCenter.default.addObserver(
            forName: UIScene.willConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            if let windowScene = notif.object as? UIWindowScene,
               windowScene.session.role == .windowExternalDisplayNonInteractive {
                self?.handleExternalSceneConnected(windowScene)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            if let windowScene = notif.object as? UIWindowScene,
               windowScene.session.role == .windowExternalDisplayNonInteractive {
                self?.handleExternalSceneDisconnected()
            }
        }
    }
    
    private func checkExistingScenes() {
        let externalScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowExternalDisplayNonInteractive }
        
        if let first = externalScenes.first {
            handleExternalSceneConnected(first)
        }
    }
    
    private func handleExternalSceneConnected(_ windowScene: UIWindowScene) {
        isExternalScreenConnected = true
        externalScreenName = "Studio TV / AirPlay"
        
        let window = UIWindow(windowScene: windowScene)
        let hostingController = UIHostingController(rootView: CleanStudioExternalTVView())
        window.rootViewController = hostingController
        window.isHidden = false
        self.externalWindow = window
    }
    
    private func handleExternalSceneDisconnected() {
        isExternalScreenConnected = false
        externalScreenName = "Žiadna TV"
        externalWindow?.isHidden = true
        externalWindow = nil
    }
}

// MARK: - Clean Studio External TV View (Clean Mirror Display)
public struct CleanStudioExternalTVView: View {
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.amberGold)
                    
                    Text("ELLEGNOTE • STUDIO AIRPLAY")
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "figure.dance")
                        .font(.system(size: 80))
                        .foregroundColor(.amberGold)
                    
                    Text("Pripravené na Full-Screen analýzu tanca")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
            }
        }
    }
}
