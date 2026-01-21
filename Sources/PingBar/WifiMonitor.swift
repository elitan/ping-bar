import Foundation
import CoreWLAN

class WifiMonitor: NSObject, CWEventDelegate {
    private let client = CWWiFiClient.shared()
    private let autoStartKey = "AutoStartSSIDs"
    var onWifiChanged: ((String?) -> Void)?

    var currentSSID: String? {
        client.interface()?.ssid()
    }

    var autoStartSSIDs: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: autoStartKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: autoStartKey)
        }
    }

    override init() {
        super.init()
        client.delegate = self
    }

    func startMonitoring() {
        try? client.startMonitoringEvent(with: .ssidDidChange)
    }

    func stopMonitoring() {
        try? client.stopMonitoringAllEvents()
    }

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        onWifiChanged?(currentSSID)
    }

    func addCurrentSSIDToAutoStart() {
        guard let ssid = currentSSID else { return }
        var ssids = autoStartSSIDs
        ssids.insert(ssid)
        autoStartSSIDs = ssids
    }

    func removeSSIDFromAutoStart(_ ssid: String) {
        var ssids = autoStartSSIDs
        ssids.remove(ssid)
        autoStartSSIDs = ssids
    }

    func shouldAutoStart() -> Bool {
        guard let ssid = currentSSID else { return false }
        return autoStartSSIDs.contains(ssid)
    }
}
