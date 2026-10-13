import Combine
import Foundation

@MainActor
final class Diagnostics: ObservableObject {
    @Published private(set) var router = MetricHistory()
    @Published private(set) var internet = MetricHistory()
    @Published private(set) var dns = MetricHistory()
    @Published private(set) var wifi: WiFiInfo?
    @Published private(set) var gatewayIP: String?
    @Published private(set) var dnsServerIP: String?
    @Published private(set) var captivePortalURL: URL?
    @Published private(set) var settings = AppSettings.current
    @Published private(set) var isRunning = false

    /// WiFi details only show in the popover, so they're only polled while it's open.
    var isPopoverShown = false {
        didSet { if isPopoverShown { wifi = WiFiInfo.current() } }
    }

    private let locationManager = LocationManager()
    private var tasks: [Task<Void, Never>] = []
    private var settingsObserver: AnyCancellable?

    init() {
        locationManager.onAuthorizationChanged = { [weak self] in
            self?.wifi = WiFiInfo.current()
        }
        settingsObserver = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.settingsDidChange() }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        tasks = [
            Task { [weak self] in
                while !Task.isCancelled, let self {
                    let started = ContinuousClock.now
                    await self.probe()
                    try? await Task.sleep(until: started + .seconds(self.settings.pingInterval), clock: .continuous)
                }
            },
            Task { [weak self] in
                while !Task.isCancelled {
                    let url = await CaptivePortal.loginURL()
                    guard !Task.isCancelled else { return }
                    self?.captivePortalURL = url
                    try? await Task.sleep(for: .seconds(10))
                }
            },
        ]
    }

    func stop() {
        tasks.forEach { $0.cancel() }
        tasks = []
        isRunning = false
        router = MetricHistory()
        internet = MetricHistory()
        dns = MetricHistory()
        dnsServerIP = nil
        captivePortalURL = nil
    }

    func requestLocationPermission() {
        locationManager.requestPermission()
    }

    /// Runs one round of probes concurrently. The loop in `start()` waits for it before scheduling the
    /// next one, so slow rounds on a bad network can't pile up.
    private func probe() async {
        let gateway = NetworkConfig.gateway
        if gateway != gatewayIP {
            gatewayIP = gateway
            router = MetricHistory()
        }
        let dnsServer = NetworkConfig.dnsServer
        dnsServerIP = dnsServer

        let target = settings.internetTarget
        let hostname = settings.dnsHostname
        async let routerLatency = offMainThread { gateway.flatMap { ICMPPing.ping($0) } }
        async let internetLatency = offMainThread { ICMPPing.ping(target) }
        async let dnsLatency = offMainThread { dnsServer.flatMap { DNSProbe.query(hostname, server: $0) } }
        let results = await (routerLatency, internetLatency, dnsLatency)

        guard !Task.isCancelled else { return }
        router.add(results.0)
        internet.add(results.1)
        dns.add(results.2)
        if isPopoverShown { wifi = WiFiInfo.current() }
    }

    private func settingsDidChange() {
        let new = AppSettings.current
        guard new != settings else { return }
        if new.internetTarget != settings.internetTarget { internet = MetricHistory() }
        if new.dnsHostname != settings.dnsHostname { dns = MetricHistory() }
        settings = new
    }
}

/// The probes block for up to their timeout, so run them on a dispatch queue rather than the main
/// actor or Swift's cooperative thread pool.
private func offMainThread<T: Sendable>(_ work: @escaping @Sendable () -> T) async -> T {
    await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .utility).async { continuation.resume(returning: work()) }
    }
}
