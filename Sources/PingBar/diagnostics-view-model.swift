import Foundation
import SwiftUI

class DiagnosticsViewModel: ObservableObject {
    private let service: DiagnosticsService

    @Published var wifiInfo: WiFiInfo?
    @Published var routerLatency: Double?
    @Published var internetLatency: Double?
    @Published var dnsLatency: Double?
    @Published var routerSmoothed: Double?
    @Published var internetSmoothed: Double?
    @Published var dnsSmoothed: Double?
    @Published var routerHistory: [Double?] = []
    @Published var internetHistory: [Double?] = []
    @Published var dnsHistory: [Double?] = []
    @Published var isRunning: Bool = false
    @Published var gatewayIP: String?
    @Published var dnsServerIP: String?
    @Published var captivePortalStatus: CaptivePortalStatus = .unknown

    init(service: DiagnosticsService) {
        self.service = service
        service.onUpdate = { [weak self] in
            self?.refresh()
        }
    }

    func refresh() {
        wifiInfo = service.wifiService.getCurrentInfo()
        routerLatency = service.routerHistory.latest
        internetLatency = service.internetHistory.latest
        dnsLatency = service.dnsHistory.latest
        routerSmoothed = service.routerHistory.recentWeightedAverage
        internetSmoothed = service.internetHistory.recentWeightedAverage
        dnsSmoothed = service.dnsHistory.recentWeightedAverage
        routerHistory = service.routerHistory.values
        internetHistory = service.internetHistory.values
        dnsHistory = service.dnsHistory.values
        isRunning = service.isRunning
        gatewayIP = service.gatewayIP
        dnsServerIP = service.dnsServerIP
        captivePortalStatus = service.captivePortalStatus
    }

    var routerLoss: Double {
        service.routerHistory.lossPercentage
    }

    var internetLoss: Double {
        service.internetHistory.lossPercentage
    }

    var routerJitter: Double? {
        service.routerHistory.jitter
    }

    var internetJitter: Double? {
        service.internetHistory.jitter
    }

    func start() {
        service.start()
        refresh()
    }

    func stop() {
        service.stop()
        refresh()
    }

    func openCaptivePortalLogin() {
        service.openCaptivePortalLogin()
    }

    func requestLocationPermission() {
        service.requestLocationPermission()
    }

    var isCaptivePortal: Bool {
        guard case .captivePortal = captivePortalStatus else { return false }
        return true
    }

    func colorForPing(_ ms: Double?, smoothed: Double? = nil) -> Color {
        return latencySwiftUIColor(smoothed ?? ms)
    }

    func colorForSignal(_ rssi: Int) -> Color {
        switch rssi {
        case (-50)...: return .green
        case (-70)...: return .orange
        default: return .red
        }
    }

    func colorForLoss(_ loss: Double) -> Color {
        switch loss {
        case 0: return .green
        case ..<5: return .orange
        default: return .red
        }
    }
}
