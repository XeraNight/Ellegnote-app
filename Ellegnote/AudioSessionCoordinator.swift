import AVFoundation

// MARK: - AudioSessionCoordinator
actor AudioSessionCoordinator {

    static let shared = AudioSessionCoordinator()
    private init() {}

    enum Client: String {
        case player, speech
    }

    private var activeClient: Client?
    private let avSession = AVAudioSession.sharedInstance()

    func activate(_ client: Client) async throws {
        // Ak iný klient drží session, bezpečne ho odovzdaj
        if let current = activeClient, current != client {
            try avSession.setActive(false, options: .notifyOthersOnDeactivation)
        }

        switch client {
        case .player:
            try avSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.allowBluetoothHFP, .allowAirPlay]
            )
            try avSession.setActive(true)

        case .speech:
            try avSession.setCategory(
                .record,
                mode: .measurement,
                options: [.duckOthers]
            )
            try avSession.setActive(true)
        }

        activeClient = client
    }

    func deactivate(_ client: Client) async {
        guard activeClient == client else { return }
        try? avSession.setActive(false, options: .notifyOthersOnDeactivation)
        activeClient = nil
    }

    var currentClient: Client? { activeClient }
}
