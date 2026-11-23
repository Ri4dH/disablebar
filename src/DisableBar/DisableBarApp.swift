import AppKit
import SwiftUI

@main
struct DisableBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    init() {
        // Figtree must be registered before the first view is drawn.
        AX.FontLoader.register()
    }

    var body: some Scene {
        Window("DisableBar", id: "main") {
            MainView()
                .environmentObject(state)
                .tint(AX.Colors.accent)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 540, height: 780)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(state)
                .tint(AX.Colors.accent)
        } label: {
            MenuBarLabel(state: state)
        }
        .menuBarExtraStyle(.window)
    }
}

/// The menu bar icon. It is always alive, so it also hands SwiftUI's
/// `openWindow` to AppState for opening the window from AppKit code.
private struct MenuBarLabel: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(nsImage: MenuBarIcon.image(off: state.isTouchBarOff && state.peekSecondsLeft == nil))
            .onAppear {
                state.openMainWindow = {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var launchedAsLoginItem = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Login items are launched with keyAELaunchedAsLogInItem in the open event.
        if let event = NSAppleEventManager.shared().currentAppleEvent,
           event.eventID == kAEOpenApplication,
           event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem {
            launchedAsLoginItem = true
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated {
            _ = Updater.shared
            let state = AppState.shared
            state.start()
            // At login, start quietly in the menu bar (unless onboarding is pending).
            if launchedAsLoginItem && state.hasCompletedOnboarding {
                DispatchQueue.main.async {
                    for window in NSApp.windows where window.title == "DisableBar" { window.close() }
                }
            }
        }
    }

    /// Opening the app again (Finder, Spotlight, Dock) shows the main window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainActor.assumeIsolated { AppState.shared.openMainWindow?() }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Leave the Touch Bar usable when the app quits.
        MainActor.assumeIsolated { AppState.shared.setTouchBarOff(false) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

/// Template image for the menu bar: a Touch Bar outline, slashed when off.
enum MenuBarIcon {
    static func image(off: Bool) -> NSImage {
        let size = NSSize(width: 22, height: 16)
        let image = NSImage(size: size, flipped: false) { _ in
            let bar = NSBezierPath(roundedRect: NSRect(x: 1.5, y: 4.5, width: 19, height: 7), xRadius: 2.5, yRadius: 2.5)
            bar.lineWidth = 1.5
            NSColor.black.setStroke()
            if off {
                bar.stroke()
                let slash = NSBezierPath()
                slash.move(to: NSPoint(x: 4, y: 1.5))
                slash.line(to: NSPoint(x: 18, y: 14.5))
                slash.lineWidth = 1.6
                slash.lineCapStyle = .round
                slash.stroke()
            } else {
                NSColor.black.setFill()
                bar.fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
