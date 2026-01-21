import Cocoa
import ServiceManagement

class StatusBarController {
    private var statusItem: NSStatusItem
    private let pingService = PingService()
    private let wifiMonitor = WifiMonitor()
    private var isRunning = false

    private var startMenuItem: NSMenuItem!
    private var stopMenuItem: NSMenuItem!
    private var autoStartMenuItem: NSMenuItem!
    private var manageNetworksMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusItem()
        setupMenu()
        setupPingService()
        setupWifiMonitor()

        if wifiMonitor.shouldAutoStart() {
            startPing()
        }
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.title = "---"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        }
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

        autoStartMenuItem = NSMenuItem(title: "Auto-start on: \(wifiMonitor.currentSSID ?? "No WiFi")", action: #selector(toggleAutoStart), keyEquivalent: "")
        autoStartMenuItem.target = self
        updateAutoStartMenuItem()
        menu.addItem(autoStartMenuItem)

        manageNetworksMenuItem = NSMenuItem(title: "Manage Networks...", action: #selector(showManageNetworks), keyEquivalent: "")
        manageNetworksMenuItem.target = self
        menu.addItem(manageNetworksMenuItem)

        menu.addItem(NSMenuItem.separator())

        launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

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

    private func setupWifiMonitor() {
        wifiMonitor.startMonitoring()
        wifiMonitor.onWifiChanged = { [weak self] ssid in
            self?.handleWifiChange(ssid: ssid)
        }
    }

    private func handleWifiChange(ssid: String?) {
        updateAutoStartMenuItem()
        if let ssid = ssid, wifiMonitor.autoStartSSIDs.contains(ssid) {
            startPing()
        } else if ssid == nil {
            updateDisplay(latency: nil)
        }
    }

    private func updateAutoStartMenuItem() {
        let ssid = wifiMonitor.currentSSID ?? "No WiFi"
        autoStartMenuItem.title = "Auto-start on: \(ssid)"
        autoStartMenuItem.isEnabled = wifiMonitor.currentSSID != nil
        autoStartMenuItem.state = wifiMonitor.shouldAutoStart() ? .on : .off
    }

    private func updateDisplay(latency: Double?) {
        guard let button = statusItem.button else { return }

        if let ms = latency {
            let rounded = Int(ms.rounded())
            button.title = "\(rounded)ms"
            button.contentTintColor = colorForLatency(ms)
        } else {
            button.title = "---"
            button.contentTintColor = .gray
        }
    }

    private func colorForLatency(_ ms: Double) -> NSColor {
        switch ms {
        case ..<50: return .systemGreen
        case ..<150: return .systemYellow
        default: return .systemRed
        }
    }

    @objc private func startPing() {
        isRunning = true
        pingService.start()
        startMenuItem.isEnabled = false
        stopMenuItem.isEnabled = true
    }

    @objc private func stopPing() {
        isRunning = false
        pingService.stop()
        startMenuItem.isEnabled = true
        stopMenuItem.isEnabled = false
        if let button = statusItem.button {
            button.title = "---"
            button.contentTintColor = .gray
        }
    }

    @objc private func toggleAutoStart() {
        if wifiMonitor.shouldAutoStart() {
            if let ssid = wifiMonitor.currentSSID {
                wifiMonitor.removeSSIDFromAutoStart(ssid)
            }
        } else {
            wifiMonitor.addCurrentSSIDToAutoStart()
        }
        updateAutoStartMenuItem()
    }

    @objc private func showManageNetworks() {
        let alert = NSAlert()
        alert.messageText = "Auto-start Networks"
        let ssids = wifiMonitor.autoStartSSIDs
        if ssids.isEmpty {
            alert.informativeText = "No networks configured."
        } else {
            alert.informativeText = "Networks:\n" + ssids.sorted().joined(separator: "\n")
        }
        alert.addButton(withTitle: "OK")
        if !ssids.isEmpty {
            alert.addButton(withTitle: "Clear All")
        }
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            wifiMonitor.autoStartSSIDs = []
            updateAutoStartMenuItem()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let newState = !isLaunchAtLoginEnabled()
        setLaunchAtLogin(enabled: newState)
        launchAtLoginMenuItem.state = newState ? .on : .off
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }

    @objc private func quit() {
        wifiMonitor.stopMonitoring()
        pingService.stop()
        NSApp.terminate(nil)
    }
}
