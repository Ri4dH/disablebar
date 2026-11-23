import SwiftUI

/// First-run sheet: explains what happens and sets up the essentials
/// before the Touch Bar goes dark for the first time.
struct OnboardingView: View {
    @EnvironmentObject private var state: AppState
    @State private var capsLockToEscape = true
    @State private var launchAtLogin = true

    var body: some View {
        VStack(alignment: .leading, spacing: AX.Space.s5) {
            VStack(alignment: .leading, spacing: AX.Space.s3) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                Text("Welcome to DisableBar").axStyle(.heading1)
                Text("Switch off a flickering Touch Bar and stop ghost touches from pressing buttons.")
                    .axStyle(.body, color: AX.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    AXItem(symbol: "power", hue: .red, title: "One click turns it off",
                           supporting: "The Touch Bar goes fully dark and ignores every touch. Quit DisableBar or switch it back on any time.") {
                        EmptyView()
                    }
                    AXDivider()
                    AXItem(symbol: "capslock.fill", hue: .green, title: "Use Caps Lock as Esc",
                           supporting: "Esc is part of the Touch Bar, so it goes dark too. Recommended.") {
                        toggle("Use Caps Lock as Esc", isOn: $capsLockToEscape)
                    }
                    AXDivider()
                    AXItem(symbol: "person.crop.circle.badge.checkmark", hue: .blue, title: "Launch at login",
                           supporting: "Start quietly in the menu bar and keep the Touch Bar off.") {
                        toggle("Launch at login", isOn: $launchAtLogin)
                    }
                    AXDivider()
                    AXItem(symbol: "command", hue: .purple, title: "Toggle from anywhere",
                           supporting: "Press the shortcut, or use the icon in the menu bar.") {
                        AXKbd(keys: ["⌃", "⌥", "⌘", "T"])
                    }
                }
            }

            HStack(spacing: AX.Space.s2) {
                Button("Not now") { finish(turnOff: false) }
                    .buttonStyle(.ax(.ghost, size: .lg))
                Spacer()
                Button {
                    finish(turnOff: true)
                } label: {
                    Label("Turn off Touch Bar", systemImage: "power")
                }
                .buttonStyle(.ax(.primary, size: .lg))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AX.Space.s6)
        .frame(width: 480)
        .background(AX.Colors.backgroundBody)
        .interactiveDismissDisabled()
    }

    private func finish(turnOff: Bool) {
        withAnimation(AX.Motion.medium) {
            state.completeOnboarding(capsLockToEscape: capsLockToEscape, launchAtLogin: launchAtLogin, turnOff: turnOff)
        }
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) { EmptyView() }
            .toggleStyle(AXSwitchStyle())
            .accessibilityLabel(title)
    }
}
