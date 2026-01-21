import Cocoa
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private let pingService = PingService()
    private var settingsWindow: NSWindow?

    private var startMenuItem: NSMenuItem!
    private var stopMenuItem: NSMenuItem!

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: 20)
        setupStatusItem()
        setupMenu()
        setupPingService()
    }

    private func setupStatusItem() {
        updateDisplay(latency: nil)
    }

    private func setupMenu() {
        let menu = NSMenu()

        startMenuItem = NSMenuItem(title: "Start", action: #selector(startPing), keyEquivalent: "s")
        startMenuItem.target = self
        menu.addItem(startMenuItem)

        stopMenuItem = NSMenuItem(title: "Stop", action: #selector(stopPing), keyEquivalent: "x")
        stopMenuItem.target = self
        stopMenuItem.isEnabled = false
        menu.addItem(stopMenuItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func setupPingService() {
        pingService.onPingResult = { [weak self] latency in
            self?.updateDisplay(latency: latency)
        }
    }

    private func updateDisplay(latency: Double?) {
        guard let button = statusItem.button else { return }

        let text: String
        let color: NSColor

        if let ms = latency {
            if ms >= 1000 {
                let seconds = ms / 1000
                text = String(format: "%.1fs", seconds)
            } else {
                text = "\(Int(ms.rounded()))ms"
            }
            color = colorForLatency(ms)
        } else {
            text = "---"
            color = .systemRed
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        ]
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }

    private func colorForLatency(_ ms: Double) -> NSColor {
        switch ms {
        case ..<50: return .systemGreen
        case ..<150: return .systemOrange
        default: return .systemRed
        }
    }

    @objc private func startPing() {
        pingService.start()
        startMenuItem.isEnabled = false
        stopMenuItem.isEnabled = true
    }

    @objc private func stopPing() {
        pingService.stop()
        startMenuItem.isEnabled = true
        stopMenuItem.isEnabled = false
        updateDisplay(latency: nil)
    }

    @objc private func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PingBar Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        settingsWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        pingService.stop()
        NSApp.terminate(nil)
    }
}
