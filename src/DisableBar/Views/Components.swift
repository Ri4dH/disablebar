import SwiftUI

enum Theme {
    static let accentOff = LinearGradient(colors: [Color(red: 1.0, green: 0.33, blue: 0.38), Color(red: 0.93, green: 0.18, blue: 0.53)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing)
    static let accentOn = LinearGradient(colors: [Color(red: 0.20, green: 0.84, blue: 0.56), Color(red: 0.10, green: 0.66, blue: 0.86)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
    static let card = Color.primary.opacity(0.045)
    static let stroke = Color.primary.opacity(0.08)
}

/// Rounded "card" container used throughout the main window.
struct Card<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            }
            content
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke))
    }
}

/// A colored rounded-square icon, System Settings style.
struct IconTile: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

/// A settings row: icon, title, subtitle and a trailing control.
struct SettingRow<Trailing: View>: View {
    let symbol: String
    let color: Color
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            IconTile(symbol: symbol, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                if let subtitle {
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}

struct RowDivider: View {
    var body: some View { Divider().padding(.leading, 52) }
}

/// Small stat tile: big number, caption below.
struct StatTile: View {
    let value: String
    let caption: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke))
    }
}

/// The big pill-shaped power button.
struct PowerButton: View {
    let isOff: Bool
    var compact = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "power")
                    .font(.system(size: compact ? 14 : 17, weight: .bold))
                Text(isOff ? "Turn Touch Bar On" : "Turn Touch Bar Off")
                    .font(.system(size: compact ? 13 : 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 10 : 14)
            .background(isOff ? Theme.accentOn : Theme.accentOff, in: Capsule())
            .shadow(color: (isOff ? Color.green : Color.pink).opacity(hovering ? 0.45 : 0.25), radius: hovering ? 14 : 8, y: 4)
            .scaleEffect(hovering ? 1.015 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        .animation(.easeInOut(duration: 0.25), value: isOff)
    }
}

/// "On" / "Off" status capsule.
struct StatusPill: View {
    let isOff: Bool
    var peeking: Int?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color, radius: 3)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.14), in: Capsule())
        .foregroundStyle(color)
    }

    private var color: Color {
        if peeking != nil { return .orange }
        return isOff ? Color(red: 1, green: 0.35, blue: 0.42) : .green
    }

    private var label: String {
        if let peeking { return "Peeking · \(peeking)s" }
        return isOff ? "Touch Bar Off" : "Touch Bar On"
    }
}

/// Keyboard shortcut "keycaps".
struct KeyCaps: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .frame(minWidth: 20, minHeight: 20)
                    .padding(.horizontal, 2)
                    .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.12)))
            }
        }
        .foregroundStyle(.secondary)
    }
}

enum Format {
    static func duration(since date: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%d:%02d", m, s)
    }

    static func number(_ n: Int) -> String {
        n.formatted(.number.notation(.compactName))
    }
}
