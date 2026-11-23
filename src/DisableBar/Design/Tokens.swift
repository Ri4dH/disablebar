// Design tokens ported from Astryx (github.com/meta/astryx, MIT License,
// Copyright (c) Meta Platforms, Inc.), Neutral theme: palette stops, semantic
// colors, spacing, radius, element sizes, type scale, shadows and motion.
// Values come from packages/themes/neutral/src/neutralTheme.ts and
// packages/core/src/theme/tokens.stylex.ts.

import AppKit
import CoreText
import SwiftUI

/// Namespace for every design token the app paints with.
enum AX {}

// MARK: - Color

extension Color {
    /// A color that follows the current appearance (light / dark).
    init(light: String, dark: String) {
        let l = NSColor(hex: light), d = NSColor(hex: dark)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? d : l
        })
    }

    init(hex: String) { self.init(nsColor: NSColor(hex: hex)) }
}

extension NSColor {
    /// `#rrggbb` or `#rrggbbaa`.
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let hasAlpha = s.count == 8
        let r = CGFloat((v >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = CGFloat((v >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = CGFloat((v >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? CGFloat(v & 0xFF) / 255 : 1
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }
}

extension AX {
    /// Semantic colors (Neutral theme, `[light, dark]`).
    enum Colors {
        // Grounds
        static let backgroundBody = Color(light: "#f1f1f1", dark: "#1b1b1b")
        static let backgroundCard = Color(light: "#ffffff", dark: "#1b1b1b")
        static let backgroundSurface = Color(light: "#ffffff", dark: "#262626")
        static let backgroundPopover = Color(light: "#ffffff", dark: "#1b1b1b")
        static let backgroundMuted = Color(light: "#f1f1f1", dark: "#111111")

        // Accent (Neutral is monochrome: ink in light mode, paper in dark)
        static let accent = Color(light: "#1b1b1b", dark: "#f1f1f1")
        static let accentMuted = Color(light: "#d4d4d4", dark: "#474747")
        static let onAccent = Color(light: "#ffffff", dark: "#111111")
        static let neutral = Color(light: "#0000000F", dark: "#ffffff1A")

        // Overlays
        static let overlayHover = Color(light: "#0000000D", dark: "#ffffff0D")
        static let overlayPressed = Color(light: "#0000001A", dark: "#ffffff1A")

        // Text & icons
        static let textPrimary = Color(light: "#000000", dark: "#ffffff")
        static let textSecondary = Color(light: "#474747", dark: "#9e9e9e")
        static let textDisabled = Color(light: "#919191", dark: "#525252")
        static let iconPrimary = Color(light: "#000000", dark: "#ffffff")
        static let iconSecondary = Color(light: "#6a6a6a", dark: "#9e9e9e")

        // Borders
        static let border = Color(light: "#00000014", dark: "#ffffff1A")
        static let borderEmphasized = Color(light: "#d4d4d4", dark: "#525252")

        // Status
        static let success = Color(light: "#198100", dark: "#64af4c")
        static let error = Color(light: "#c9303a", dark: "#ff705d")
        static let warning = Color(hex: "#ffce2f")
        static let info = Color(light: "#0074e2", dark: "#6d9cfe")
        static let onError = Color(light: "#ffffff", dark: "#111111")

        static let successMuted = Color(light: "#bce0bb", dark: "#90ca903D")
        static let errorMuted = Color(light: "#ffc4be", dark: "#ff98903D")
        static let warningMuted = Color(light: "#fae19e", dark: "#e2b6233D")
        static let infoMuted = Color(light: "#b9d7ff", dark: "#88bcff3D")

        static let onSuccessMuted = Color(light: "#00490b", dark: "#90ca90")
        static let onErrorMuted = Color(light: "#76000c", dark: "#ffaea7")
        static let onWarningMuted = Color(light: "#4b3900", dark: "#eec448")
        static let onInfoMuted = Color(light: "#003978", dark: "#a1caff")
    }

    /// Named hues: a muted ground, an icon color and a text color per hue.
    enum Hue: CaseIterable {
        case red, orange, yellow, green, teal, cyan, blue, purple, pink, gray

        var background: Color {
            switch self {
            case .red: Color(light: "#ffc4be", dark: "#5b2b28")
            case .orange: Color(light: "#ffc7a1", dark: "#503424")
            case .yellow: Color(light: "#fae19e", dark: "#453a1c")
            case .green: Color(light: "#bce0bb", dark: "#2b422b")
            case .teal: Color(light: "#a9e2d6", dark: "#28413c")
            case .cyan: Color(light: "#9ae2f4", dark: "#274046")
            case .blue: Color(light: "#b9d7ff", dark: "#253c5a")
            case .purple: Color(light: "#f7d5ff", dark: "#4a2f51")
            case .pink: Color(light: "#ffc0d7", dark: "#572b3d")
            case .gray: Color(light: "#e2e2e2", dark: "#303030")
            }
        }

        var icon: Color {
            switch self {
            case .red: Color(light: "#76000c", dark: "#ff9890")
            case .orange: Color(light: "#622700", dark: "#ff9e55")
            case .yellow: Color(light: "#4b3900", dark: "#e2b623")
            case .green: Color(light: "#00490b", dark: "#90ca90")
            case .teal: Color(light: "#00463d", dark: "#81c9bb")
            case .cyan: Color(light: "#004351", dark: "#71c7dd")
            case .blue: Color(light: "#003978", dark: "#88bcff")
            case .purple: Color(light: "#5c0e6c", dark: "#e496f6")
            case .pink: Color(light: "#70003f", dark: "#fd92bd")
            case .gray: Color(light: "#474747", dark: "#9e9e9e")
            }
        }

        var text: Color {
            switch self {
            case .red: Color(light: "#76000c", dark: "#ffaea7")
            case .orange: Color(light: "#622700", dark: "#ffb37e")
            case .yellow: Color(light: "#4b3900", dark: "#eec448")
            case .green: Color(light: "#00490b", dark: "#90ca90")
            case .teal: Color(light: "#00463d", dark: "#90d7c8")
            case .cyan: Color(light: "#004351", dark: "#85d5e9")
            case .blue: Color(light: "#003978", dark: "#a1caff")
            case .purple: Color(light: "#5c0e6c", dark: "#eaacf8")
            case .pink: Color(light: "#70003f", dark: "#ffa9ca")
            case .gray: Color(light: "#1b1b1b", dark: "#d4d4d4")
            }
        }
    }
}

// MARK: - Spacing, radius, sizes

extension AX {
    /// 4-pt spacing ladder: `Space.s3` = `--spacing-3` = 12 pt.
    enum Space {
        static let s0: CGFloat = 0
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s8: CGFloat = 32
    }

    enum Radius {
        static let inner: CGFloat = 6
        static let element: CGFloat = 10
        static let container: CGFloat = 12
        static let page: CGFloat = 28
    }

    /// Control heights (`--size-element-*`).
    enum Size {
        static let elementSm: CGFloat = 28
        static let elementMd: CGFloat = 32
        static let elementLg: CGFloat = 36
        static let border: CGFloat = 1
    }
}

// MARK: - Typography

extension AX {
    /// Astryx text roles on a 14-pt base, 1.2 ratio scale, set in Figtree.
    enum TypeStyle {
        case display3, heading1, heading2, heading3, heading4, heading5
        case large, body, label, supporting, caption

        var size: CGFloat {
            switch self {
            case .display3: 29
            case .heading1: 24
            case .heading2: 20
            case .heading3, .large: 17
            case .heading4, .body, .label: 14
            case .heading5, .supporting: 12
            case .caption: 10
            }
        }

        var weight: Font.Weight {
            switch self {
            case .display3, .heading1, .heading2, .heading5, .large: .semibold
            case .heading3, .heading4: .bold // Neutral: bold h3/h4
            case .label: .medium
            case .body, .supporting, .caption: .regular
            }
        }

        var font: Font { AX.font(size: size, weight: weight) }
    }

    /// Figtree at a weight, or the system font if it isn't available.
    static func font(size: CGFloat, weight: Font.Weight) -> Font {
        guard FontLoader.isFigtreeAvailable else { return .system(size: size, weight: weight) }
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "FigtreeLight-Bold"
        case .semibold: name = "FigtreeLight-SemiBold"
        case .medium: name = "FigtreeLight-Medium"
        default: name = "FigtreeLight-Regular"
        }
        return .custom(name, size: size)
    }

    /// Registers the bundled Figtree faces (SIL OFL 1.1) for this process.
    enum FontLoader {
        private(set) static var isFigtreeAvailable = false

        static func register() {
            guard let dir = Bundle.main.resourceURL?.appendingPathComponent("Fonts"),
                  let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            else { return }
            for url in files where url.pathExtension == "woff2" {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
            isFigtreeAvailable = NSFont(name: "FigtreeLight-Regular", size: 12) != nil
        }
    }
}

extension Text {
    func axStyle(_ style: AX.TypeStyle, color: Color = AX.Colors.textPrimary) -> some View {
        self.font(style.font).foregroundStyle(color)
    }
}

// MARK: - Motion

extension AX {
    /// Neutral motion: fast 125 ms, medium 300 ms, standard ease
    /// `cubic-bezier(0.24, 1, 0.4, 1)`.
    enum Motion {
        static let fast = Animation.timingCurve(0.24, 1, 0.4, 1, duration: 0.125)
        static let medium = Animation.timingCurve(0.24, 1, 0.4, 1, duration: 0.3)
        static let slow = Animation.timingCurve(0.24, 1, 0.4, 1, duration: 0.7)
        static let exit = Animation.timingCurve(0.3, 0, 0.6, 0.6, duration: 0.125)
    }
}

// MARK: - Elevation

extension AX {
    enum Elevation { case none, low, med, high }
}

private struct ElevationModifier<S: InsettableShape>: ViewModifier {
    let elevation: AX.Elevation
    let shape: S
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let dark = scheme == .dark
        // (alpha light, alpha dark, y, blur) for two drop layers, plus a dark-mode bezel.
        let layers: [(Double, Double, CGFloat, CGFloat)]
        let bezel: Double
        switch elevation {
        case .none: layers = []; bezel = 0
        case .low: layers = [(0.05, 0.25, 2, 4), (0.10, 0.40, 4, 8)]; bezel = 0.08
        case .med: layers = [(0.05, 0.35, 2, 4), (0.10, 0.50, 4, 12)]; bezel = 0.12
        case .high: layers = [(0.10, 0.50, 4, 6), (0.15, 0.70, 12, 24)]; bezel = 0.15
        }
        return content
            .background {
                ZStack {
                    ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
                        shape.fill(Color.black)
                            .shadow(color: .black.opacity(dark ? layer.1 : layer.0), radius: layer.3 / 2, y: layer.2)
                    }
                }
            }
            .overlay {
                if dark && bezel > 0 {
                    shape.strokeBorder(Color.white.opacity(bezel), lineWidth: 1)
                }
            }
    }
}

extension View {
    /// Astryx `--shadow-low/med/high`: two soft drops, and in dark mode a 1-pt
    /// white bezel that catches the rim of the surface.
    func axElevation<S: InsettableShape>(_ elevation: AX.Elevation, in shape: S) -> some View {
        modifier(ElevationModifier(elevation: elevation, shape: shape))
    }
}

// MARK: - Fixed palette stops (for surfaces that are always dark, like the Touch Bar)

extension AX {
    enum Palette {
        static let yellow = Color(hex: "#e2b623")
        static let blue = Color(hex: "#88bcff")
        static let purple = Color(hex: "#e496f6")
        static let red = Color(hex: "#ff9890")
        static let green = Color(hex: "#90ca90")
    }
}
