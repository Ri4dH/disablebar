// Renders the DisableBar app icon to a 1024×1024 PNG.
// Usage: swift scripts/make-icon.swift <output.png>
import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "icon_1024.png"
let size: CGFloat = 1024

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// macOS icon grid: 824pt squircle centred in a 1024 canvas.
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

// Drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.45).cgColor)
NSColor.black.setFill()
tilePath.fill()
ctx.restoreGState()

// Background gradient
ctx.saveGState()
tilePath.addClip()
NSGradient(colors: [NSColor(hex: 0x303030), NSColor(hex: 0x111111)])!
    .draw(in: tile, angle: -90)
// Soft pink glow behind the bar
NSGradient(colors: [NSColor(hex: 0xff705d).withAlphaComponent(0.20), .clear])!
    .draw(fromCenter: NSPoint(x: 512, y: 512), radius: 0, toCenter: NSPoint(x: 512, y: 512), radius: 420, options: [])
ctx.restoreGState()

// Inner top highlight
ctx.saveGState()
tilePath.addClip()
NSColor.white.withAlphaComponent(0.10).setStroke()
let highlight = NSBezierPath(roundedRect: tile.insetBy(dx: 2, dy: 2), xRadius: 183, yRadius: 183)
highlight.lineWidth = 4
highlight.stroke()
ctx.restoreGState()

// The Touch Bar
let bar = NSRect(x: 172, y: 452, width: 680, height: 120)
let barPath = NSBezierPath(roundedRect: bar, xRadius: 30, yRadius: 30)
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 40, color: NSColor(hex: 0x6d9cfe).withAlphaComponent(0.30).cgColor)
NSColor.black.setFill()
barPath.fill()
ctx.restoreGState()
NSGradient(colors: [NSColor.white.withAlphaComponent(0.35), NSColor.white.withAlphaComponent(0.06)])!
    .draw(in: barPath, angle: -90)
NSColor.black.setFill()
NSBezierPath(roundedRect: bar.insetBy(dx: 5, dy: 5), xRadius: 26, yRadius: 26).fill()

// Faint keys inside the bar
let keyColor = NSColor(hex: 0x303030)
keyColor.setFill()
for (x, w) in [(195.0, 90.0), (310.0, 70.0), (395.0, 70.0), (480.0, 70.0), (640.0, 60.0), (715.0, 60.0)] {
    NSBezierPath(roundedRect: NSRect(x: x, y: 478, width: w, height: 68), xRadius: 12, yRadius: 12).fill()
}

// Slash across the bar: dark gap + gradient stroke
func slashPath() -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: 300, y: 250))
    p.line(to: NSPoint(x: 724, y: 774))
    p.lineCapStyle = .round
    return p
}
let gap = slashPath()
gap.lineWidth = 120
NSColor(hex: 0x1b1b1b).setStroke()
ctx.saveGState()
tilePath.addClip()
gap.stroke()
ctx.restoreGState()

let slash = slashPath()
slash.lineWidth = 66
ctx.saveGState()
ctx.addPath(slash.cgPathCompat)
ctx.setLineWidth(66)
ctx.setLineCap(.round)
ctx.replacePathWithStrokedPath()
ctx.clip()
NSGradient(colors: [NSColor(hex: 0xff705d), NSColor(hex: 0xff9890)])!
    .draw(in: NSRect(x: 250, y: 200, width: 524, height: 624), angle: 60)
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("wrote \(output)")

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension NSBezierPath {
    var cgPathCompat: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            switch element(at: i, associatedPoints: &points) {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo, .cubicCurveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo: path.addQuadCurve(to: points[1], control: points[0])
            case .closePath: path.closeSubpath()
            @unknown default: break
            }
        }
        return path
    }
}
