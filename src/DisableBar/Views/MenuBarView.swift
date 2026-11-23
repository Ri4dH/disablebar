import SwiftUI

/// The popover shown from the menu bar icon.
struct MenuBarView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DisableBar").font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                StatusPill(isOff: state.isTouchBarOff, peeking: state.peekSecondsLeft)
            }

            TouchBarPreview(isOff: state.isTouchBarOff && state.peekSecondsLeft == nil,
                            blockedTouches: state.blockedTouchesSession, height: 30)

            PowerButton(isOff: state.isTouchBarOff, compact: true) { state.toggle() }

            if state.isTouchBarOff {
                menuRow(state.peekSecondsLeft.map { "Hide now (\($0)s)" } ?? "Peek for \(state.peekDuration)s",
                        symbol: "eye") {
                    state.peekSecondsLeft == nil ? state.peek() : state.cancelPeek()
                }
                HStack {
                    Image(systemName: "hand.raised.fill").foregroundStyle(.pink)
                    Text("\(state.blockedTouchesSession) ghost touches blocked")
                        .monospacedDigit()
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
            }

            Divider()

            menuRow("Open DisableBar…", symbol: "macwindow") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            menuRow("Restart Touch Bar…", symbol: "arrow.clockwise") { state.restartTouchBar() }
            menuRow("Quit", symbol: "xmark.circle", shortcut: "⌘Q") { NSApp.terminate(nil) }
        }
        .padding(14)
        .frame(width: 290)
    }

    private func menuRow(_ title: String, symbol: String, shortcut: String? = nil,
                         action: @escaping () -> Void) -> some View {
        MenuRow(title: title, symbol: symbol, shortcut: shortcut, action: action)
    }
}

private struct MenuRow: View {
    let title: String
    let symbol: String
    let shortcut: String?
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).frame(width: 16)
                Text(title).monospacedDigit()
                Spacer()
                if let shortcut { Text(shortcut).foregroundStyle(.secondary) }
            }
            .font(.system(size: 13))
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(hovering ? Color.primary.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
