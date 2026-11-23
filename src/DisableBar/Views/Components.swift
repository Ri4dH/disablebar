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
    static func number(_ n: Int) -> String {
        n.formatted(.number.notation(.compactName))
    }
}
