import Foundation

class DiagnosticsService {
    let wifiService = WiFiService()
    let dnsService = DNSService()
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
    private var currentSSID: String?
    private(set) var captivePortalStatus: CaptivePortalStatus = .unknown

    var onUpdate: (() -> Void)?

    init() {
        locationManager.onAuthorizationChanged = { [weak self] _ in
            self?.onUpdate?()
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        currentSSID = wifiService.getCurrentInfo()?.ssid
        refreshGateway()
        internetPingService = PingService(target: "1.1.1.1")

        checkCaptivePortal()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        if let gateway = gatewayIP {
            routerPingService = PingService(target: gateway)
        } else {
            routerPingService = nil
        }
        routerHistory.clear()
    }

    private func detectGateway() -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/sbin/route")
        process.arguments = ["-n", "get", "default"]
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
            if trimmed.hasPrefix("gateway:") {
                return trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    func clear() {
        routerHistory.clear()
        internetHistory.clear()
        dnsHistory.clear()
    }
}
