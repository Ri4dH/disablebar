import AppKit
import Sparkle

/// Sparkle auto-updates. The feed URL and EdDSA public key live in Info.plist
/// (written by scripts/build-app.sh); without them (e.g. `swift run`) the
/// updater stays off.
@MainActor
final class Updater: NSObject, ObservableObject, SPUStandardUserDriverDelegate {
    static let shared = Updater()

    @Published private(set) var canCheckForUpdates = false
    @Published var automaticallyChecks = false {
        didSet {
            guard isConfigured, controller.updater.automaticallyChecksForUpdates != automaticallyChecks else { return }
            controller.updater.automaticallyChecksForUpdates = automaticallyChecks
        }
    }

    let isConfigured = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
    private var controller: SPUStandardUpdaterController!
    private var observation: NSKeyValueObservation?

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    override private init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: self)
        guard isConfigured else { return }
        controller.startUpdater()
        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            let can = updater.canCheckForUpdates
            Task { @MainActor in self?.canCheckForUpdates = can }
        }
    }

    func checkForUpdates() {
        guard isConfigured else { return }
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }

    // DisableBar is a menu bar app, so let Sparkle show gentle reminders
    // instead of stealing focus for scheduled update checks.
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }
}
