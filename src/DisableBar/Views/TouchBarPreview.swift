import SwiftUI

/// A stylised, animated rendering of the Touch Bar that mirrors its state.
///
/// * On: glowing buttons with a faint flicker (the problem we're fixing).
/// * Off: pure black with a shield; every blocked ghost touch shows a ripple.
struct TouchBarPreview: View {
    let isOff: Bool
    var blockedTouches: Int = 0
    var height: CGFloat = 46

    @State private var ripples: [Ripple] = []
    @State private var flicker = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: height * 0.22, style: .continuous)
                    .fill(Color.black)

                if isOff {
                    offContent
                        .transition(.opacity)
                } else {
                    onContent(width: geo.size.width)
                        .opacity(flicker ? 0.78 : 1)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                ForEach(ripples) { ripple in
                    RippleView(ripple: ripple)
                        .position(x: ripple.x * geo.size.width, y: geo.size.height / 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: height * 0.22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: height * 0.22, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                                 startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: isOff ? .clear : Color.cyan.opacity(0.18), radius: 14)
        }
        .frame(height: height)
        .animation(.easeInOut(duration: 0.45), value: isOff)
        .onChange(of: blockedTouches) { _ in addRipple() }
        .task(id: isOff) { await flickerLoop() }
    }

    private var offContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.shield.fill")
            Text("TOUCH BAR OFF")
                .tracking(2)
        }
        .font(.system(size: height * 0.24, weight: .semibold, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.16))
    }

    private func onContent(width: CGFloat) -> some View {
        let h = height * 0.66
        return HStack(spacing: height * 0.12) {
            key("esc", width: h * 1.5, h: h)
            Spacer(minLength: 2)
            ForEach(["chevron.left", "arrow.clockwise", "magnifyingglass", "plus"], id: \.self) { symbol in
                symbolKey(symbol, width: h * 1.35, h: h)
            }
            Spacer(minLength: 2)
            HStack(spacing: 2) {
                symbolKey("chevron.left", width: h * 0.7, h: h, tint: .gray)
                symbolKey("sun.max.fill", width: h * 1.1, h: h, tint: .yellow)
                symbolKey("speaker.wave.2.fill", width: h * 1.1, h: h, tint: .cyan)
                symbolKey("mic.fill", width: h * 1.1, h: h, tint: .purple)
            }
        }
        .padding(.horizontal, height * 0.14)
    }

    private func key(_ text: String, width: CGFloat, h: CGFloat) -> some View {
        Text(text)
            .font(.system(size: h * 0.38, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: width, height: h)
            .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: h * 0.2))
    }

    private func symbolKey(_ symbol: String, width: CGFloat, h: CGFloat, tint: Color = .white) -> some View {
        Image(systemName: symbol)
            .font(.system(size: h * 0.4, weight: .semibold))
            .foregroundStyle(tint.opacity(0.92))
            .frame(width: width, height: h)
            .background(Color.white.opacity(0.13), in: RoundedRectangle(cornerRadius: h * 0.2))
    }

    /// Irregular brief dips in brightness while the bar is on.
    private func flickerLoop() async {
        flicker = false
        guard !isOff else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_200_000_000...3_500_000_000))
            for _ in 0..<Int.random(in: 1...3) {
                flicker = true
                try? await Task.sleep(nanoseconds: 60_000_000)
                flicker = false
                try? await Task.sleep(nanoseconds: 70_000_000)
            }
        }
    }

    private func addRipple() {
        guard isOff else { return }
        let ripple = Ripple(x: .random(in: 0.06...0.94))
        ripples.append(ripple)
        if ripples.count > 8 { ripples.removeFirst() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

private struct Ripple: Identifiable {
    let id = UUID()
    let x: CGFloat
}

private struct RippleView: View {
    let ripple: Ripple
    @State private var expanded = false

    var body: some View {
        Circle()
            .strokeBorder(Color.pink.opacity(0.9), lineWidth: 2)
            .frame(width: 14, height: 14)
            .scaleEffect(expanded ? 3.2 : 0.4)
            .opacity(expanded ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { expanded = true }
            }
    }
}
