// Components modelled on Astryx's Button, Switch, Card, Badge, Banner, Item,
// SegmentedControl and Kbd (github.com/meta/astryx, MIT), drawn with AX tokens.

import SwiftUI

// MARK: - Button

struct AXButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, ghost, destructive }
    enum Size { case sm, md, lg }

    var variant: Variant = .secondary
    var size: Size = .md
    var fillsWidth = false

    func makeBody(configuration: Configuration) -> some View {
        AXButtonBody(configuration: configuration, variant: variant, size: size, fillsWidth: fillsWidth)
    }
}

private struct AXButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let variant: AXButtonStyle.Variant
    let size: AXButtonStyle.Size
    let fillsWidth: Bool
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    private var height: CGFloat {
        switch size {
        case .sm: AX.Size.elementSm
        case .md: AX.Size.elementMd
        case .lg: AX.Size.elementLg
        }
    }

    private var fill: Color {
        switch variant {
        case .primary: AX.Colors.accent
        case .secondary: AX.Colors.neutral
        case .ghost: .clear
        case .destructive: AX.Colors.errorMuted
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: AX.Colors.onAccent
        case .secondary, .ghost: AX.Colors.textPrimary
        case .destructive: AX.Colors.onErrorMuted
        }
    }

    private func tint(pressed: Bool) -> Color {
        guard pressed || hovering else { return .clear }
        if variant == .primary { return AX.Colors.onAccent.opacity(pressed ? 0.2 : 0.1) }
        return pressed ? AX.Colors.overlayPressed : AX.Colors.overlayHover
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AX.Radius.element, style: .continuous)
        configuration.label
            .font(AX.font(size: size == .sm ? 12 : 14, weight: .medium))
            .foregroundStyle(foreground)
            .labelStyle(AXButtonLabelStyle())
            .padding(.horizontal, size == .sm ? AX.Space.s2 + 2 : AX.Space.s3)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: height)
            .background(shape.fill(fill))
            .overlay {
                // Hover / press tint (Astryx --color-overlay-hover / -pressed);
                // on the accent fill the tint is drawn in the on-accent ink.
                shape.fill(tint(pressed: configuration.isPressed))
            }
            .axElevation(variant == .primary ? .low : .none, in: shape)
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.5)
            .onHover { hovering = $0 }
            .animation(AX.Motion.fast, value: hovering)
            .animation(AX.Motion.fast, value: configuration.isPressed)
    }
}

private struct AXButtonLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: AX.Space.s2) {
            configuration.icon
            configuration.title
        }
    }
}

extension ButtonStyle where Self == AXButtonStyle {
    static func ax(_ variant: AXButtonStyle.Variant = .secondary, size: AXButtonStyle.Size = .md,
                   fillsWidth: Bool = false) -> AXButtonStyle {
        AXButtonStyle(variant: variant, size: size, fillsWidth: fillsWidth)
    }
}

// MARK: - Switch

/// Astryx Switch: accent track when on, emphasized-border track when off.
struct AXSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        AXSwitch(isOn: configuration.$isOn, label: configuration.label)
    }
}

private struct AXSwitch<Label: View>: View {
    @Binding var isOn: Bool
    let label: Label
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: AX.Space.s2) {
            label
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? AX.Colors.accent : AX.Colors.borderEmphasized)
                    .frame(width: 36, height: 20)
                Circle()
                    .fill(isOn ? AX.Colors.onAccent : (scheme == .dark ? Color(hex: "#e2e2e2") : .white))
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
                    .padding(2)
            }
            .animation(AX.Motion.medium, value: isOn)
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(Capsule())
            .onTapGesture { if isEnabled { isOn.toggle() } }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAction { isOn.toggle() }
    }
}

// MARK: - Card

struct AXCard<Content: View>: View {
    var padding: CGFloat = AX.Space.s4
    var elevation: AX.Elevation = .none
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AX.Radius.container, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(AX.Colors.backgroundCard))
            .overlay(shape.strokeBorder(AX.Colors.border, lineWidth: AX.Size.border))
            .axElevation(elevation, in: shape)
    }
}

/// A titled group of rows (Astryx Section + Card).
struct AXSection<Content: View>: View {
    let title: String
    var description: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AX.Space.s2) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).axStyle(.heading4)
                if let description {
                    Text(description).axStyle(.supporting, color: AX.Colors.textSecondary)
                }
            }
            .padding(.horizontal, AX.Space.s1)
            AXCard(padding: 0) {
                VStack(spacing: 0) { content }
            }
        }
    }
}

// MARK: - Item row

/// Astryx Item: leading media, a label with supporting text, trailing content.
struct AXItem<Trailing: View>: View {
    let symbol: String
    let hue: AX.Hue
    let title: String
    var supporting: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: AX.Space.s3) {
            AXIconTile(symbol: symbol, hue: hue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).axStyle(.label)
                if let supporting {
                    Text(supporting)
                        .axStyle(.supporting, color: AX.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: AX.Space.s3)
            trailing
        }
        .padding(.horizontal, AX.Space.s4)
        .padding(.vertical, AX.Space.s3)
    }
}

struct AXIconTile: View {
    let symbol: String
    let hue: AX.Hue
    var size: CGFloat = AX.Size.elementMd

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(hue.icon)
            .frame(width: size, height: size)
            .background(hue.background, in: RoundedRectangle(cornerRadius: AX.Radius.inner + 2, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct AXDivider: View {
    var inset: CGFloat = AX.Space.s4 + AX.Size.elementMd + AX.Space.s3

    var body: some View {
        Rectangle()
            .fill(AX.Colors.border)
            .frame(height: AX.Size.border)
            .padding(.leading, inset)
    }
}

// MARK: - Badge

struct AXBadge: View {
    let text: String
    var hue: AX.Hue = .gray
    var showsDot = false

    var body: some View {
        HStack(spacing: 6) {
            if showsDot {
                Circle().fill(hue.icon).frame(width: 6, height: 6).accessibilityHidden(true)
            }
            Text(text)
                .font(AX.font(size: 12, weight: .medium))
                .monospacedDigit()
        }
        .foregroundStyle(hue.text)
        .padding(.horizontal, AX.Space.s2)
        .frame(height: 22)
        .background(hue.background, in: Capsule())
        .animation(AX.Motion.medium, value: text)
    }
}

// MARK: - Banner

struct AXBanner<Action: View>: View {
    enum Status { case info, success, warning, error }

    let status: Status
    let title: String
    var message: String?
    @ViewBuilder var action: Action

    private var ground: Color {
        switch status {
        case .info: AX.Colors.infoMuted
        case .success: AX.Colors.successMuted
        case .warning: AX.Colors.warningMuted
        case .error: AX.Colors.errorMuted
        }
    }

    private var ink: Color {
        switch status {
        case .info: AX.Colors.onInfoMuted
        case .success: AX.Colors.onSuccessMuted
        case .warning: AX.Colors.onWarningMuted
        case .error: AX.Colors.onErrorMuted
        }
    }

    private var symbol: String {
        switch status {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: AX.Space.s3) {
            Image(systemName: symbol).font(.system(size: 15, weight: .semibold))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AX.TypeStyle.label.font)
                if let message {
                    Text(message).font(AX.TypeStyle.supporting.font).opacity(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: AX.Space.s2)
            action
        }
        .foregroundStyle(ink)
        .padding(AX.Space.s3)
        .background(ground, in: RoundedRectangle(cornerRadius: AX.Radius.container, style: .continuous))
    }
}

extension AXBanner where Action == EmptyView {
    init(status: Status, title: String, message: String? = nil) {
        self.init(status: status, title: title, message: message) { EmptyView() }
    }
}

// MARK: - Segmented control

struct AXSegmented<Value: Hashable>: View {
    struct Option: Identifiable {
        let value: Value
        let title: String
        var symbol: String?
        var id: String { title }
    }

    @Binding var selection: Value
    let options: [Option]
    var size: AXButtonStyle.Size = .md
    @Namespace private var namespace

    private var height: CGFloat { size == .sm ? AX.Size.elementSm : AX.Size.elementMd }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                let selected = option.value == selection
                Button {
                    withAnimation(AX.Motion.medium) { selection = option.value }
                } label: {
                    HStack(spacing: 6) {
                        if let symbol = option.symbol {
                            Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
                        }
                        Text(option.title)
                    }
                    .font(AX.font(size: size == .sm ? 12 : 13, weight: .medium))
                    .foregroundStyle(selected ? AX.Colors.textPrimary : AX.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: height - 8)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: AX.Radius.inner + 1, style: .continuous)
                                .fill(AX.Colors.backgroundSurface)
                                .axElevation(.low, in: RoundedRectangle(cornerRadius: AX.Radius.inner + 1, style: .continuous))
                                .matchedGeometryEffect(id: "thumb", in: namespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(AX.Space.s1)
        .background(AX.Colors.neutral, in: RoundedRectangle(cornerRadius: AX.Radius.element, style: .continuous))
    }
}

// MARK: - Kbd

struct AXKbd: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(AX.font(size: 11, weight: .medium))
                    .foregroundStyle(AX.Colors.textSecondary)
                    .frame(minWidth: 20, minHeight: 20)
                    .padding(.horizontal, 3)
                    .background(AX.Colors.backgroundSurface, in: RoundedRectangle(cornerRadius: AX.Radius.inner - 1))
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: AX.Radius.inner - 1)
                            .strokeBorder(AX.Colors.borderEmphasized, lineWidth: 1)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(keys.joined(separator: " "))
    }
}

// MARK: - Stat

/// A metric tile: supporting label, large tabular value, tinted icon.
struct AXStat: View {
    let label: String
    let value: String
    let symbol: String
    let hue: AX.Hue

    var body: some View {
        AXCard(padding: AX.Space.s4) {
            VStack(alignment: .leading, spacing: AX.Space.s3) {
                HStack(spacing: AX.Space.s2) {
                    AXIconTile(symbol: symbol, hue: hue, size: 22)
                    Text(label).axStyle(.supporting, color: AX.Colors.textSecondary)
                        .lineLimit(1)
                }
                Text(value)
                    .font(AX.font(size: 24, weight: .semibold))
                    .foregroundStyle(AX.Colors.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        // Read as one element: "Blocked now, 26".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

// MARK: - Hoverable row (menus)

struct AXMenuRow: View {
    let title: String
    let symbol: String
    var shortcut: String?
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AX.Space.s2) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AX.Colors.iconSecondary)
                    .frame(width: 18)
                    .accessibilityHidden(true)
                Text(title).font(AX.TypeStyle.body.font).foregroundStyle(AX.Colors.textPrimary)
                    .monospacedDigit()
                Spacer()
                if let shortcut {
                    Text(shortcut).font(AX.TypeStyle.supporting.font).foregroundStyle(AX.Colors.textSecondary)
                }
            }
            .padding(.horizontal, AX.Space.s2)
            .frame(height: AX.Size.elementSm)
            .background(hovering ? AX.Colors.overlayHover : .clear,
                        in: RoundedRectangle(cornerRadius: AX.Radius.inner, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(AX.Motion.fast, value: hovering)
    }
}
