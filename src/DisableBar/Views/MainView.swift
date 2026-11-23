import SwiftUI

/// The main window, laid out with Astryx (Neutral) tokens and components.
struct MainView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject private var updater = Updater.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AX.Space.s6) {
                header
                hero
                if state.controlStripSuspended { frozenBanner }
                stats
                behaviorSection
                escapeSection
                layoutSection
                updatesSection
                troubleshootingSection
                footer
            }
            .padding(.horizontal, AX.Space.s6)
            .padding(.top, AX.Space.s2)
            .padding(.bottom, AX.Space.s6)
        }
        .scrollIndicators(.never)
        .safeAreaInset(edge: .top, spacing: 0) {
            // Keeps scrolled content clear of the traffic lights.
            AX.Colors.backgroundBody.frame(height: 40)
        }
        .ignoresSafeArea(.container, edges: .top)
        .frame(width: 540)
        .frame(minHeight: 520, idealHeight: 780, maxHeight: 1400)
        .background(AX.Colors.backgroundBody.ignoresSafeArea())
        .overlay(alignment: .bottom) { toast }
        .onAppear { state.refreshSystemStatus() }
        .sheet(isPresented: Binding(get: { !state.hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView().environmentObject(state)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: AX.Space.s3) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("DisableBar").axStyle(.heading2)
                Text("Switch off a flickering Touch Bar.")
                    .axStyle(.supporting, color: AX.Colors.textSecondary)
            }
            Spacer()
            StatusBadge(isOff: state.isTouchBarOff, peeking: state.peekSecondsLeft)
        }
    }

    // MARK: Hero

    private var hero: some View {
        AXCard(padding: AX.Space.s5, elevation: .med) {
            VStack(alignment: .leading, spacing: AX.Space.s4) {
                TouchBarPreview(isOff: state.isTouchBarOff && state.peekSecondsLeft == nil,
                                blockedTouches: state.blockedTouchesSession)

                Button {
                    withAnimation(AX.Motion.medium) { state.toggle() }
                } label: {
                    Label(state.isTouchBarOff ? "Turn on Touch Bar" : "Turn off Touch Bar", systemImage: "power")
                }
                .buttonStyle(.ax(.primary, size: .lg, fillsWidth: true))
                .keyboardShortcut(.defaultAction)

                HStack(spacing: AX.Space.s2) {
                    if state.isTouchBarOff {
                        Button {
                            state.peekSecondsLeft == nil ? state.peek() : state.cancelPeek()
                        } label: {
                            Label(state.peekSecondsLeft.map { "Hide now · \($0)s" } ?? "Peek for \(peekLabel)",
                                  systemImage: state.peekSecondsLeft == nil ? "eye" : "eye.slash")
                                .monospacedDigit()
                        }
                        .buttonStyle(.ax(.ghost, size: .sm))
                    }
                    Spacer()
                    if state.hotKeyEnabled {
                        Text("Shortcut").axStyle(.supporting, color: AX.Colors.textSecondary)
                        AXKbd(keys: ["⌃", "⌥", "⌘", "T"])
                    }
                }
                .frame(height: AX.Size.elementSm)

                if !state.isSupported {
                    AXBanner(status: .warning, title: "Not supported on this macOS",
                             message: "The Touch Bar overlay API isn't available.")
                } else if !state.hasTouchBar {
                    AXBanner(status: .info, title: "No Touch Bar detected",
                             message: "DisableBar only has an effect on MacBook Pros with a Touch Bar.")
                }
            }
        }
    }

    private var peekLabel: String {
        state.peekDuration >= 60 ? "\(state.peekDuration / 60) min" : "\(state.peekDuration)s"
    }

    private var frozenBanner: some View {
        AXBanner(status: .info, title: "Control Strip is frozen",
                 message: "The ControlStrip process is suspended, so the right side of the Touch Bar won't respond.") {
            Button("Unfreeze") { state.unfreezeControlStrip() }
                .buttonStyle(.ax(.secondary, size: .sm))
        }
    }

    // MARK: Stats

    private var stats: some View {
        HStack(spacing: AX.Space.s3) {
            AXStat(label: "Blocked now", value: Format.number(state.blockedTouchesSession),
                   symbol: "hand.raised.fill", hue: .pink)
            AXStat(label: "Blocked all-time", value: Format.number(state.blockedTouchesTotal),
                   symbol: "shield.lefthalf.filled", hue: .purple)
        }
    }

    // MARK: Settings

    private var behaviorSection: some View {
        AXSection(title: "Behavior") {
            AXItem(symbol: "bolt.fill", hue: .orange, title: "Turn off when DisableBar starts",
                   supporting: "Keep the Touch Bar dark from the moment the app launches.") {
                axSwitch("Turn off when DisableBar starts", isOn: $state.turnOffAtLaunch)
            }
            AXDivider()
            AXItem(symbol: "person.crop.circle.badge.checkmark", hue: .blue, title: "Launch at login") {
                axSwitch("Launch at login", isOn: $state.launchAtLogin)
            }
            AXDivider()
            AXItem(symbol: "command", hue: .purple, title: "Global shortcut",
                   supporting: "Press ⌃⌥⌘T anywhere to switch the Touch Bar on or off.") {
                axSwitch("Global shortcut", isOn: $state.hotKeyEnabled)
            }
            AXDivider()
            AXItem(symbol: "eye.fill", hue: .teal, title: "Peek duration",
                   supporting: "How long Peek shows the Touch Bar.") {
                AXSegmented(selection: $state.peekDuration, options: [
                    .init(value: 10, title: "10s"), .init(value: 30, title: "30s"),
                    .init(value: 60, title: "1m"), .init(value: 300, title: "5m"),
                ], size: .sm)
                .frame(width: 176)
            }
        }
    }

    private var escapeSection: some View {
        AXSection(title: "Escape key", description: "Touch Bar Macs have no physical Esc key.") {
            AXItem(symbol: "capslock.fill", hue: .green, title: "Caps Lock acts as Esc",
                   supporting: "Remaps Caps Lock to Esc. No extra permissions needed.") {
                axSwitch("Caps Lock acts as Esc", isOn: $state.capsLockToEscape)
            }
            AXDivider()
            AXItem(symbol: "keyboard", hue: .gray, title: "Keep a dim Esc key on the Touch Bar",
                   supporting: "Needs Accessibility permission. Ghost touches may still press it.") {
                axSwitch("Keep a dim Esc key on the Touch Bar", isOn: $state.showEscKey)
            }
        }
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: AX.Space.s2) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Layout when on").axStyle(.heading4)
                Text("What the Touch Bar shows while it's switched on.")
                    .axStyle(.supporting, color: AX.Colors.textSecondary)
            }
            .padding(.horizontal, AX.Space.s1)
            AXSegmented(selection: Binding(get: { state.touchBarMode }, set: { state.setMode($0) }),
                        options: TouchBarMode.allCases.map { .init(value: $0, title: $0.title, symbol: $0.symbol) })
        }
    }

    private var updatesSection: some View {
        AXSection(title: "Updates") {
            AXItem(symbol: "arrow.down.circle.fill", hue: .cyan, title: "Check for updates automatically",
                   supporting: "Version \(Updater.currentVersion)") {
                HStack(spacing: AX.Space.s3) {
                    Button("Check now") { updater.checkForUpdates() }
                        .buttonStyle(.ax(.secondary, size: .sm))
                        .disabled(!updater.canCheckForUpdates)
                    axSwitch("Check for updates automatically", isOn: $updater.automaticallyChecks)
                        .disabled(!updater.isConfigured)
                }
            }
        }
    }

    private var troubleshootingSection: some View {
        AXSection(title: "Troubleshooting") {
            AXItem(symbol: "arrow.clockwise", hue: .red, title: "Restart Touch Bar",
                   supporting: "Restarts TouchBarServer and the Control Strip. Asks for your password.") {
                Button("Restart…") { state.restartTouchBar() }
                    .buttonStyle(.ax(.secondary, size: .sm))
            }
            AXDivider()
            AXItem(symbol: "chart.bar.fill", hue: .gray, title: "Reset statistics") {
                Button("Reset") { withAnimation(AX.Motion.medium) { state.resetStats() } }
                    .buttonStyle(.ax(.secondary, size: .sm))
            }
        }
    }

    private var footer: some View {
        Text("DisableBar covers the OLED Touch Bar with pure black, so its pixels are physically off, and absorbs every touch. Nothing on your system is modified, and quitting the app restores the Touch Bar.")
            .axStyle(.supporting, color: AX.Colors.textDisabled)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AX.Space.s4)
    }

    // MARK: Toast

    @ViewBuilder private var toast: some View {
        if let message = state.lastMessage {
            let shape = RoundedRectangle(cornerRadius: AX.Radius.element, style: .continuous)
            Label(message, systemImage: "checkmark.circle.fill")
                .font(AX.TypeStyle.label.font)
                .foregroundStyle(AX.Colors.textPrimary)
                .padding(.horizontal, AX.Space.s4)
                .frame(height: AX.Size.elementLg + 4)
                .background(shape.fill(AX.Colors.backgroundPopover))
                .overlay(shape.strokeBorder(AX.Colors.border))
                .axElevation(.high, in: shape)
                .padding(.bottom, AX.Space.s5)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(AX.Motion.medium, value: state.lastMessage)
        }
    }

    private func axSwitch(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) { EmptyView() }
            .toggleStyle(AXSwitchStyle())
            .accessibilityLabel(title)
    }
}
