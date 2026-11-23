import SwiftUI

/// The popover shown from the menu bar icon.
struct MenuBarView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: AX.Space.s3) {
            HStack {
                Text("DisableBar").axStyle(.heading4)
                Spacer()
                StatusBadge(isOff: state.isTouchBarOff, peeking: state.peekSecondsLeft)
            }

            TouchBarPreview(isOff: state.isTouchBarOff && state.peekSecondsLeft == nil,
                            blockedTouches: state.blockedTouchesSession, height: 30)

            Button {
                withAnimation(AX.Motion.medium) { state.toggle() }
            } label: {
                Label(state.isTouchBarOff ? "Turn on Touch Bar" : "Turn off Touch Bar", systemImage: "power")
            }
            .buttonStyle(.ax(.primary, size: .md, fillsWidth: true))

            if state.isTouchBarOff {
                HStack(spacing: AX.Space.s2) {
                    Button {
                        state.peekSecondsLeft == nil ? state.peek() : state.cancelPeek()
                    } label: {
                        Label(state.peekSecondsLeft.map { "Hide · \($0)s" } ?? "Peek",
                              systemImage: state.peekSecondsLeft == nil ? "eye" : "eye.slash")
                            .monospacedDigit()
                    }
                    .buttonStyle(.ax(.secondary, size: .sm))
                    Spacer()
                    Image(systemName: "hand.raised.fill").font(.system(size: 10)).foregroundStyle(AX.Hue.pink.icon)
                        .accessibilityHidden(true)
                    Text("\(state.blockedTouchesSession) blocked")
                        .axStyle(.supporting, color: AX.Colors.textSecondary)
                        .monospacedDigit()
                }
            }

            Rectangle().fill(AX.Colors.border).frame(height: 1)

            VStack(spacing: 2) {
                AXMenuRow(title: "Open DisableBar…", symbol: "macwindow") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                AXMenuRow(title: "Restart Touch Bar…", symbol: "arrow.clockwise") { state.restartTouchBar() }
                AXMenuRow(title: "Quit", symbol: "xmark.circle", shortcut: "⌘Q") { NSApp.terminate(nil) }
            }
            .padding(.horizontal, -AX.Space.s2)
        }
        .padding(AX.Space.s4)
        .frame(width: 292)
        .background(AX.Colors.backgroundPopover)
    }
}
