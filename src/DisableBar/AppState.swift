import AppKit
import ApplicationServices
import ServiceManagement
import SwiftUI
import TouchBarPrivate

/// Single source of truth for the app: Touch Bar state, settings and stats.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: Live state

    @Published private(set) var isTouchBarOff = false
    @Published private(set) var peekSecondsLeft: Int?
    @Published private(set) var blockedTouchesSession = 0
    @Published private(set) var controlStripSuspended = false
    @Published private(set) var touchBarMode: TouchBarMode = SystemTouchBar.mode
    @Published private(set) var lastMessage: String?

    let isSupported = BlackoutTouchBar.isSupported
    let hasTouchBar = TBHasTouchBar()

    // MARK: Settings (persisted)

    @Published var blockedTouchesTotal: Int {
        didSet { defaults.set(blockedTouchesTotal, forKey: Keys.blockedTotal) }
    }
    @Published var turnOffAtLaunch: Bool {
        didSet { defaults.set(turnOffAtLaunch, forKey: Keys.turnOffAtLaunch) }
    }
    @Published var showEscKey: Bool {
        didSet {
            defaults.set(showEscKey, forKey: Keys.showEscKey)
            if showEscKey { requestAccessibilityIfNeeded() }
            if isTouchBarOff { blackout.present(showEscKey: showEscKey) }
        }
    }
    @Published var capsLockToEscape: Bool {
        didSet {
            defaults.set(capsLockToEscape, forKey: Keys.capsLock)
            KeyRemapper.setCapsLockToEscape(capsLockToEscape)
        }
    }
    @Published var hotKeyEnabled: Bool {
        didSet {
            defaults.set(hotKeyEnabled, forKey: Keys.hotKey)
            updateHotKey()
        }
    }
    @Published var peekDuration: Int {
        didSet { defaults.set(peekDuration, forKey: Keys.peekDuration) }
    }
    @Published var launchAtLogin: Bool {
        didSet { updateLoginItem() }
    }
    @Published private(set) var hasCompletedOnboarding: Bool

    /// Opens the main window; set by a view that has SwiftUI's `openWindow`.
    var openMainWindow: (() -> Void)?

    // MARK: Private

    private enum Keys {
        static let blockedTotal = "blockedTouchesTotal"
        static let turnOffAtLaunch = "turnOffAtLaunch"
        static let showEscKey = "showEscKey"
        static let capsLock = "capsLockToEscape"
        static let hotKey = "hotKeyEnabled"
        static let peekDuration = "peekDuration"
        static let onboarded = "hasCompletedOnboarding"
    }

    private let defaults = UserDefaults.standard
    private let blackout = BlackoutTouchBar()
    private var hotKey: HotKey?
    private var peekTimer: Timer?
    private var watchdog: Timer?
    private var serverPID: pid_t?
    private var pendingTouchSave = 0

    private init() {
        defaults.register(defaults: [
            Keys.turnOffAtLaunch: true,
            Keys.hotKey: true,
            Keys.peekDuration: 30,
        ])
        blockedTouchesTotal = defaults.integer(forKey: Keys.blockedTotal)
        turnOffAtLaunch = defaults.bool(forKey: Keys.turnOffAtLaunch)
        showEscKey = defaults.bool(forKey: Keys.showEscKey)
        capsLockToEscape = defaults.bool(forKey: Keys.capsLock)
        hotKeyEnabled = defaults.bool(forKey: Keys.hotKey)
        peekDuration = defaults.integer(forKey: Keys.peekDuration)
        launchAtLogin = SMAppService.mainApp.status == .enabled
        // People upgrading from 1.1 already know the app: skip onboarding.
        let saved = defaults.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "") ?? [:]
        if saved[Keys.onboarded] == nil, saved[Keys.blockedTotal] != nil || saved[Keys.turnOffAtLaunch] != nil {
            defaults.set(true, forKey: Keys.onboarded)
        }
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarded)

        blackout.onBlockedTouch = { [weak self] in self?.recordBlockedTouch() }
        blackout.onEscape = { [weak self] in self?.postEscape() }
    }

    /// Called once the app has finished launching.
    func start() {
        updateHotKey()
        if capsLockToEscape { KeyRemapper.setCapsLockToEscape(true) }
        refreshSystemStatus()
        observeSystemEvents()
        if turnOffAtLaunch && hasCompletedOnboarding { setTouchBarOff(true) }
    }

    // MARK: - Actions

    /// Applies the first-run choices and remembers that onboarding is done.
    func completeOnboarding(capsLockToEscape: Bool, launchAtLogin: Bool, turnOff: Bool) {
        if capsLockToEscape != self.capsLockToEscape { self.capsLockToEscape = capsLockToEscape }
        if launchAtLogin != self.launchAtLogin { self.launchAtLogin = launchAtLogin }
        defaults.set(true, forKey: Keys.onboarded)
        hasCompletedOnboarding = true
        if turnOff { setTouchBarOff(true) }
    }

    func toggle() { setTouchBarOff(!isTouchBarOff || peekSecondsLeft != nil) }

    func setTouchBarOff(_ off: Bool) {
        cancelPeek()
        guard isSupported else {
            flash("This version of macOS doesn't expose the Touch Bar overlay API.")
            return
        }
        if off {
            blackout.present(showEscKey: showEscKey)
            isTouchBarOff = true
            blockedTouchesSession = 0
            startWatchdog()
        } else {
            blackout.dismiss()
            isTouchBarOff = false
            stopWatchdog()
        }
    }

    /// Shows the normal Touch Bar for `peekDuration` seconds, then turns it off again.
    func peek() {
        guard isTouchBarOff else { return }
        cancelPeek()
        blackout.dismiss()
        peekSecondsLeft = peekDuration
        peekTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let left = self.peekSecondsLeft else { return }
                if left <= 1 {
                    self.cancelPeek()
                    self.blackout.present(showEscKey: self.showEscKey)
                } else {
                    self.peekSecondsLeft = left - 1
                }
            }
        }
    }

    func cancelPeek() {
        peekTimer?.invalidate()
        peekTimer = nil
        peekSecondsLeft = nil
    }

    func setMode(_ mode: TouchBarMode) {
        SystemTouchBar.setMode(mode)
        touchBarMode = mode
        reassertAfterDelay()
        flash("Touch Bar layout set to \(mode.title).")
    }

    func restartTouchBar() {
        if SystemTouchBar.restartTouchBarServer() {
            flash("Touch Bar restarted.")
            reassertAfterDelay(seconds: 2)
        }
        refreshSystemStatus()
    }

    func unfreezeControlStrip() {
        SystemTouchBar.restartControlStrip()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.refreshSystemStatus() }
        flash("Control Strip restarted.")
    }

    func resetStats() {
        blockedTouchesTotal = 0
        blockedTouchesSession = 0
    }

    func refreshSystemStatus() {
        controlStripSuspended = SystemTouchBar.isControlStripSuspended()
        touchBarMode = SystemTouchBar.mode
        if launchAtLogin != (SMAppService.mainApp.status == .enabled) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        // People upgrading from 1.1 already know the app: skip onboarding.
        let saved = defaults.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "") ?? [:]
        if saved[Keys.onboarded] == nil, saved[Keys.blockedTotal] != nil || saved[Keys.turnOffAtLaunch] != nil {
            defaults.set(true, forKey: Keys.onboarded)
        }
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarded)
        }
    }

    // MARK: - Internals

    private func recordBlockedTouch() {
        blockedTouchesSession += 1
        blockedTouchesTotal += 1
    }

    private func flash(_ message: String) {
        lastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            if self?.lastMessage == message { self?.lastMessage = nil }
        }
    }

    private func updateHotKey() {
        hotKey = hotKeyEnabled ? HotKey { [weak self] in self?.toggle() } : nil
    }

    private func updateLoginItem() {
        let service = SMAppService.mainApp
        do {
            if launchAtLogin, service.status != .enabled {
                try service.register()
            } else if !launchAtLogin, service.status == .enabled {
                try service.unregister()
            }
        } catch {
            flash("Couldn't update login item: \(error.localizedDescription)")
        }
    }

    private func requestAccessibilityIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Sends an Escape key press (requires Accessibility permission).
    private func postEscape() {
        guard AXIsProcessTrusted() else {
            requestAccessibilityIfNeeded()
            return
        }
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(keyboardEventSource: source, virtualKey: 0x35, keyDown: true)?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: source, virtualKey: 0x35, keyDown: false)?.post(tap: .cghidEventTap)
    }

    /// Re-applies the blackout after anything that can reset the Touch Bar.
    private func reassertAfterDelay(seconds: Double = 1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self, self.isTouchBarOff, self.peekSecondsLeft == nil else { return }
            self.blackout.present(showEscKey: self.showEscKey)
        }
    }

    /// TouchBarServer can crash or be restarted by macOS; when its PID changes
    /// our overlay is gone, so present it again.
    private func startWatchdog() {
        serverPID = SystemTouchBar.touchBarServerPID()
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let pid = SystemTouchBar.touchBarServerPID()
                if pid != self.serverPID {
                    self.serverPID = pid
                    if pid != nil { self.reassertAfterDelay() }
                }
            }
        }
    }

    private func stopWatchdog() {
        watchdog?.invalidate()
        watchdog = nil
    }

    private func observeSystemEvents() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
        ]
        for name in names {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.reassertAfterDelay(seconds: 1.5)
                    self?.refreshSystemStatus()
                }
            }
        }
    }
}
