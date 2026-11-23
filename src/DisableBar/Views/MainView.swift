import SwiftUI

/// The main window.
struct MainView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                hero
                if state.controlStripSuspended { frozenBanner }
                stats
                behaviorCard
                escapeCard
                layoutCard
                troubleshootingCard
                footer
            }
            .padding(20)
        }
        .frame(width: 520)
        .frame(minHeight: 520, idealHeight: 760, maxHeight: 1400)
        .background(.background)
        .overlay(alignment: .bottom) { toast }
        .onAppear { state.refreshSystemStatus() }
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("DisableBar").font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Switch off a flickering Touch Bar.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            StatusPill(isOff: state.isTouchBarOff, peeking: state.peekSecondsLeft)
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        VStack(spacing: 16) {
            TouchBarPreview(isOff: state.isTouchBarOff && state.peekSecondsLeft == nil,
                            blockedTouches: state.blockedTouchesSession)
                .padding(.horizontal, 4)

            PowerButton(isOff: state.isTouchBarOff) { state.toggle() }

            HStack {
                if state.isTouchBarOff {
                    Button {
                        state.peekSecondsLeft == nil ? state.peek() : state.cancelPeek()
                    } label: {
                        Label(state.peekSecondsLeft.map { "Hide now (\($0)s)" } ?? "Peek for \(state.peekDuration)s",
                              systemImage: state.peekSecondsLeft == nil ? "eye" : "eye.slash")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12, weight: .medium))
                }
                Spacer()
                if state.hotKeyEnabled {
                    HStack(spacing: 6) {
                        Text("Shortcut").font(.system(size: 11)).foregroundStyle(.secondary)
                        KeyCaps(keys: ["⌃", "⌥", "⌘", "T"])
                    }
                }
            }
            .frame(height: 22)

            if !state.isSupported {
                Label("This macOS version doesn't provide the Touch Bar overlay API.", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12)).foregroundStyle(.orange)
            } else if !state.hasTouchBar {
                Label("No Touch Bar detected on this Mac.", systemImage: "info.circle")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Color.primary.opacity(0.06), Color.primary.opacity(0.02)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.stroke))
    }

    private var frozenBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "snowflake").font(.system(size: 18)).foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("Control Strip is frozen").font(.system(size: 13, weight: .semibold))
                Text("The ControlStrip process is suspended, so the right side of the Touch Bar won't respond or update.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Unfreeze") { state.unfreezeControlStrip() }
                .controlSize(.small)
        }
        .padding(14)
        .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.cyan.opacity(0.25)))
    }

    private var stats: some View {
        HStack(spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                StatTile(value: state.offSince.map { Format.duration(since: $0, now: context.date) } ?? "—",
                         caption: "Off for", symbol: "timer", tint: .orange)
            }
            StatTile(value: Format.number(state.blockedTouchesSession),
                     caption: "Ghost touches blocked", symbol: "hand.raised.fill", tint: .pink)
            StatTile(value: Format.number(state.blockedTouchesTotal),
                     caption: "Blocked all-time", symbol: "shield.lefthalf.filled", tint: .purple)
        }
    }

    private var behaviorCard: some View {
        Card(title: "Behavior") {
            SettingRow(symbol: "bolt.fill", color: .orange, title: "Turn off when DisableBar starts",
                       subtitle: "Keep the Touch Bar dark from the moment the app launches.") {
                Toggle("", isOn: $state.turnOffAtLaunch).labelsHidden().toggleStyle(.switch)
            }
            RowDivider()
            SettingRow(symbol: "person.crop.circle.badge.checkmark", color: .blue, title: "Launch at login") {
                Toggle("", isOn: $state.launchAtLogin).labelsHidden().toggleStyle(.switch)
            }
            RowDivider()
            SettingRow(symbol: "command", color: .indigo, title: "Global shortcut",
                       subtitle: "Press ⌃⌥⌘T anywhere to switch the Touch Bar on or off.") {
                Toggle("", isOn: $state.hotKeyEnabled).labelsHidden().toggleStyle(.switch)
            }
            RowDivider()
            SettingRow(symbol: "eye.fill", color: .teal, title: "Peek duration",
                       subtitle: "How long “Peek” shows the Touch Bar before switching it off again.") {
                Picker("", selection: $state.peekDuration) {
                    Text("10s").tag(10)
                    Text("30s").tag(30)
                    Text("1m").tag(60)
                    Text("5m").tag(300)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 70)
            }
        }
    }

    private var escapeCard: some View {
        Card(title: "Escape key") {
            SettingRow(symbol: "capslock.fill", color: .green, title: "Caps Lock acts as Esc",
                       subtitle: "Your Mac has no physical Esc key. Remaps Caps Lock → Esc with no extra permissions.") {
                Toggle("", isOn: $state.capsLockToEscape).labelsHidden().toggleStyle(.switch)
            }
            RowDivider()
            SettingRow(symbol: "escape", color: .gray, title: "Keep a dim Esc key on the Touch Bar",
                       subtitle: "Shows a faint “esc” while the bar is off. Needs Accessibility permission; ghost touches may still press it.") {
                Toggle("", isOn: $state.showEscKey).labelsHidden().toggleStyle(.switch)
            }
        }
    }

    private var layoutCard: some View {
        Card(title: "Touch Bar layout (when on)") {
            Picker("", selection: Binding(get: { state.touchBarMode }, set: { state.setMode($0) })) {
                ForEach(TouchBarMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private var troubleshootingCard: some View {
        Card(title: "Troubleshooting") {
            SettingRow(symbol: "arrow.clockwise", color: .red, title: "Restart Touch Bar",
                       subtitle: "Restarts TouchBarServer and the Control Strip. Fixes a frozen or glitching bar. Asks for your password.") {
                Button("Restart") { state.restartTouchBar() }.controlSize(.small)
            }
            RowDivider()
            SettingRow(symbol: "chart.bar.fill", color: .purple, title: "Reset statistics") {
                Button("Reset") { state.resetStats() }.controlSize(.small)
            }
        }
    }

    private var footer: some View {
        Text("DisableBar covers the OLED Touch Bar with pure black, so its pixels are physically off, and absorbs every touch. Nothing is modified on your system, and quitting the app restores the Touch Bar.")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }

    @ViewBuilder private var toast: some View {
        if let message = state.lastMessage {
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .shadow(radius: 8, y: 2)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: state.lastMessage)
        }
    }
}
