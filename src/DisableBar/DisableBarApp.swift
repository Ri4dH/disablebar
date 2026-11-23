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
            Image(nsImage: MenuBarIcon.image(off: state.isTouchBarOff && state.peekSecondsLeft == nil))
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated { AppState.shared.start() }
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
