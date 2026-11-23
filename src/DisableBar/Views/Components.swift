import SwiftUI

/// The Touch Bar state as an Astryx badge.
struct StatusBadge: View {
    let isOff: Bool
    var peeking: Int?

    var body: some View {
        if let peeking {
            AXBadge(text: "Peeking · \(peeking)s", hue: .orange, showsDot: true)
        } else if isOff {
            AXBadge(text: "Touch Bar off", hue: .red, showsDot: true)
        } else {
            AXBadge(text: "Touch Bar on", hue: .green, showsDot: true)
        }
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
