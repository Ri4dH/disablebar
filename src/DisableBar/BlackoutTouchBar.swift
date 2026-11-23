import AppKit
import TouchBarPrivate

/// A pitch-black view that fills the Touch Bar.
///
/// The Touch Bar is an OLED panel, so black pixels emit no light: showing this
/// view is visually the same as switching the panel off. It also swallows every
/// touch, so phantom ("ghost") touches can no longer press hidden buttons.
final class BlackoutView: NSView {
    var onTouch: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        allowedTouchTypes = .direct
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var intrinsicContentSize: NSSize { NSSize(width: 1400, height: 30) }

    override func touchesBegan(with event: NSEvent) {
        let count = event.touches(matching: .began, in: self).count
        for _ in 0..<max(count, 1) { onTouch?() }
    }
}

/// A very dim "esc" key shown while the Touch Bar is off (optional).
final class DimEscapeView: NSView {
    var onPress: (() -> Void)?
    private let label = NSTextField(labelWithString: "esc")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        allowedTouchTypes = .direct
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = NSColor(white: 0.32, alpha: 1)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var intrinsicContentSize: NSSize { NSSize(width: 64, height: 30) }

    override func touchesBegan(with event: NSEvent) {
        label.textColor = NSColor(white: 0.7, alpha: 1)
    }

    override func touchesEnded(with event: NSEvent) {
        label.textColor = NSColor(white: 0.32, alpha: 1)
        onPress?()
    }

    override func touchesCancelled(with event: NSEvent) {
        label.textColor = NSColor(white: 0.32, alpha: 1)
    }
}

/// Owns the full-width system-modal Touch Bar used to black out the panel.
@MainActor
final class BlackoutTouchBar: NSObject, NSTouchBarDelegate {
    private static let fillID = NSTouchBarItem.Identifier("app.disablebar.blackout")
    private static let escID = NSTouchBarItem.Identifier("app.disablebar.esc")

    private var touchBar: NSTouchBar?
    private(set) var isPresented = false

    /// Called on the main actor for every touch absorbed by the black overlay.
    var onBlockedTouch: (() -> Void)?
    /// Called when the dim Esc key is tapped.
    var onEscape: (() -> Void)?

    static var isSupported: Bool { TBSystemModalAvailable() }

    func present(showEscKey: Bool) {
        dismiss()
        let bar = NSTouchBar()
        bar.delegate = self
        bar.defaultItemIdentifiers = [Self.fillID]
        bar.escapeKeyReplacementItemIdentifier = showEscKey ? Self.escID : nil
        touchBar = bar
        TBPresentSystemModal(bar)
        isPresented = true
    }

    func dismiss() {
        guard let bar = touchBar else { return }
        TBDismissSystemModal(bar)
        touchBar = nil
        isPresented = false
    }

    nonisolated func touchBar(_ touchBar: NSTouchBar,
                              makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        MainActor.assumeIsolated {
            let item = NSCustomTouchBarItem(identifier: identifier)
            if identifier == Self.escID {
                let view = DimEscapeView(frame: NSRect(x: 0, y: 0, width: 64, height: 30))
                view.onPress = { [weak self] in self?.onEscape?() }
                item.view = view
            } else {
                let view = BlackoutView(frame: NSRect(x: 0, y: 0, width: 1400, height: 30))
                view.onTouch = { [weak self] in self?.onBlockedTouch?() }
                item.view = view
            }
            return item
        }
    }
}
