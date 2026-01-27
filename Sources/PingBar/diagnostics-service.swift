import Foundation

class DiagnosticsService {
    let wifiService = WiFiService()
    private(set) var dnsService: DNSService
    let captivePortalService = CaptivePortalService()
    let locationManager = LocationManager()

    private var routerPingService: PingService?
    private var internetPingService: PingService?

    let routerHistory = MetricHistory()
    let internetHistory = MetricHistory()
    let dnsHistory = MetricHistory()

    private var timer: Timer?
    private var captivePortalTimer: Timer?
    private(set) var isRunning = false
    private(set) var gatewayIP: String?
    private(set) var dnsServerIP: String?
    private var currentSSID: String?
    private(set) var captivePortalStatus: CaptivePortalStatus = .unknown

    var onUpdate: (() -> Void)?
    private var intervalObserver: NSObjectProtocol?
    private var targetsObserver: NSObjectProtocol?

    var internetTarget: String {
        let stored = UserDefaults.standard.string(forKey: "internetTarget") ?? ""
        return stored.isEmpty ? Defaults.internetTarget : stored
    }

    var dnsHostname: String {
        let stored = UserDefaults.standard.string(forKey: "dnsHostname") ?? ""
        return stored.isEmpty ? Defaults.dnsHostname : stored
    }

    init() {
        let hostname = UserDefaults.standard.string(forKey: "dnsHostname") ?? ""
        dnsService = DNSService(hostname: hostname.isEmpty ? Defaults.dnsHostname : hostname)

        locationManager.onAuthorizationChanged = { [weak self] _ in
            self?.onUpdate?()
        }
        intervalObserver = NotificationCenter.default.addObserver(
            forName: .pingIntervalChanged, object: nil, queue: .main
        ) { [weak self] _ in
            self?.restartTimer()
        }
        targetsObserver = NotificationCenter.default.addObserver(
            forName: .pingTargetsChanged, object: nil, queue: .main
        ) { [weak self] _ in
            self?.restartTargets()
        }
    }

    deinit {
        [intervalObserver, targetsObserver].compactMap { $0 }.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }

    private func restartTargets() {
        internetPingService = PingService(target: internetTarget)
        dnsService = DNSService(hostname: dnsHostname)
        internetHistory.clear()
        dnsHistory.clear()
        onUpdate?()
    }

    private var pingInterval: TimeInterval {
        let stored = UserDefaults.standard.double(forKey: "pingInterval")
        return stored > 0 ? stored : Defaults.pingInterval
    }

    private func restartTimer() {
        guard isRunning else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        currentSSID = wifiService.getCurrentInfo()?.ssid
        refreshGateway()
        internetPingService = PingService(target: internetTarget)

        checkCaptivePortal()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        captivePortalTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkCaptivePortal()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        captivePortalTimer?.invalidate()
        captivePortalTimer = nil
        isRunning = false
        clear()
        captivePortalStatus = .unknown
        onUpdate?()
    }

    private func checkCaptivePortal() {
        captivePortalService.check { [weak self] status in
            self?.captivePortalStatus = status
            self?.onUpdate?()
        }
    }

    func openCaptivePortalLogin() {
        if case .captivePortal(let url) = captivePortalStatus {
            captivePortalService.openLoginPage(url: url)
        }
    }

    func requestLocationPermission() {
        locationManager.requestPermission()
    }

    var hasLocationPermission: Bool {
        locationManager.isAuthorized
    }

    private func tick() {
        let newSSID = wifiService.getCurrentInfo()?.ssid
        if newSSID != currentSSID {
            currentSSID = newSSID
            DispatchQueue.main.async {
                self.refreshGateway()
            }
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            let routerLatency = self.routerPingService?.executePing()
            let internetLatency = self.internetPingService?.executePing()
            let dnsLatency = self.dnsService.lookup()

            DispatchQueue.main.async {
                self.routerHistory.add(routerLatency)
                self.internetHistory.add(internetLatency)
                self.dnsHistory.add(dnsLatency)
                self.onUpdate?()
            }
        }
    }

    private func refreshGateway() {
        gatewayIP = detectGateway()
        dnsServerIP = detectDNSServer()
        routerPingService = gatewayIP.map { PingService(target: $0) }
        routerHistory.clear()
    }

    private func detectGateway() -> String? {
        runCommand("/sbin/route", args: ["-n", "get", "default"], linePrefix: "gateway:")
    }

    private func detectDNSServer() -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--dns"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        var currentNameserver: String?
        var isSupplemental = false

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("resolver #") {
                if let ns = currentNameserver, !isSupplemental {
                    return ns
                }
                currentNameserver = nil
                isSupplemental = false
            } else if trimmed.hasPrefix("nameserver[0]") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count >= 2 {
                    currentNameserver = parts[1].trimmingCharacters(in: .whitespaces)
                }
            } else if trimmed.hasPrefix("flags") && trimmed.contains("Supplemental") {
                isSupplemental = true
            }
        }

        if let ns = currentNameserver, !isSupplemental {
            return ns
        }
        return nil
    }

    private func runCommand(_ path: String, args: [String], linePrefix: String) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(linePrefix) {
                return trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    func clear() {
        routerHistory.clear()
        internetHistory.clear()
        dnsHistory.clear()
        dnsServerIP = nil
    }
}
