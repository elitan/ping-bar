import Cocoa
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private let diagnosticsService = DiagnosticsService()
    private var settingsWindow: NSWindow?
    private var popover: NSPopover!
    private var viewModel: DiagnosticsViewModel!

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: 45)
        setupStatusItem()
        setupPopover()
        setupDiagnosticsService()
    }

    private func setupStatusItem() {
        updateDisplay(latency: nil, smoothedLatency: nil)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        viewModel = DiagnosticsViewModel(service: diagnosticsService)

        let diagnosticsView = DiagnosticsView(
            viewModel: viewModel,
            onSettings: { [weak self] in
                self?.popover.close()
                self?.showSettings()
            },
            onQuit: { [weak self] in
                self?.quit()
            }
        )

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.contentViewController = NSHostingController(rootView: diagnosticsView)
    }

    private func setupDiagnosticsService() {
        diagnosticsService.onUpdate = { [weak self] in
            guard let self = self else { return }
            let latency = self.diagnosticsService.isRunning ? self.diagnosticsService.internetHistory.latest : nil
            let smoothed = self.diagnosticsService.isRunning ? self.diagnosticsService.internetHistory.recentWeightedAverage : nil
            self.updateDisplay(latency: latency, smoothedLatency: smoothed)
            self.viewModel.refresh()
        }
    }

    private func updateDisplay(latency: Double?, smoothedLatency: Double?) {
        guard let button = statusItem.button else { return }

        let (text, color): (String, NSColor) = {
            guard diagnosticsService.isRunning else {
                return ("---", .secondaryLabelColor)
            }
            guard let ms = latency else {
                return ("---", .systemRed)
            }
            if ms >= 1000 {
                return (String(format: "%.1fs", ms / 1000), latencyColor(smoothedLatency))
            }
            return ("\(Int(ms.rounded()))ms", latencyColor(smoothedLatency))
        }()

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        ]
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.close()
        } else {
            viewModel.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showSettings() {
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

    private func quit() {
        diagnosticsService.stop()
        NSApp.terminate(nil)
    }
}
