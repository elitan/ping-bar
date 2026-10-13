import Cocoa
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: 45)
    private let diagnostics = Diagnostics()
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var displayObserver: AnyCancellable?

    override init() {
        super.init()

        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: DiagnosticsView(
            diagnostics: diagnostics,
            onSettings: { [weak self] in self?.showSettings() },
            onQuit: { NSApp.terminate(nil) }
        ))

        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        displayObserver = Publishers.CombineLatest3(diagnostics.$internet, diagnostics.$isRunning, diagnostics.$settings)
            .sink { [weak self] internet, isRunning, settings in
                self?.updateButton(internet: internet, isRunning: isRunning, iconMode: settings.showIconMode)
            }

        diagnostics.start()
    }

    private func updateButton(internet: MetricHistory, isRunning: Bool, iconMode: Bool) {
        guard let button = statusItem.button else { return }
        let color = isRunning ? latencyColor(internet) : .secondaryLabelColor

        if iconMode {
            statusItem.length = NSStatusItem.squareLength
            button.attributedTitle = NSAttributedString()
            button.image = tintedSymbol("wifi", color: color)
        } else {
            statusItem.length = 45
            button.image = nil
            button.attributedTitle = NSAttributedString(
                string: isRunning ? formatLatency(internet.latest) : "---",
                attributes: [
                    .foregroundColor: color,
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                ]
            )
        }
    }

    /// Menu bar images are normally templated to black/white, so draw a non-template colored copy.
    private func tintedSymbol(_ name: String, color: NSColor) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: "Ping status")?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .medium)) else { return nil }
        let image = NSImage(size: symbol.size, flipped: false) { rect in
            symbol.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        image.isTemplate = false
        return image
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard let button = statusItem.button else { return }
        // Activating the app lets the transient popover close when the user clicks anywhere else.
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func popoverWillShow(_ notification: Notification) {
        diagnostics.isPopoverShown = true
    }

    func popoverDidClose(_ notification: Notification) {
        diagnostics.isPopoverShown = false
    }

    private func showSettings() {
        popover.performClose(nil)

        if settingsWindow == nil {
            let hostingView = NSHostingView(rootView: SettingsView())
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "PingBar Settings"
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
