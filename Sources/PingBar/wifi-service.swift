import Foundation
import CoreWLAN

struct WiFiInfo {
    let ssid: String?
    let rssi: Int
    let noise: Int
    let channel: Int
    let band: String
    let wifiStandard: String
    let linkRate: Double

    var signalQuality: Int {
        let snr = rssi - noise
        return max(0, min(100, (snr + 10) * 2))
    }
}

class WiFiService {
    private let client = CWWiFiClient.shared()

    func getCurrentInfo() -> WiFiInfo? {
        guard let interface = client.interface() else { return nil }
        guard interface.powerOn() else { return nil }

        let channel = interface.wlanChannel()?.channelNumber ?? 0
        let band: String
        switch channel {
        case 1...14: band = "2.4 GHz"
        case 33...177: band = "5 GHz"
        default: band = "6 GHz"
        }

        let wifiStandard: String
        switch interface.activePHYMode() {
        case .mode11a, .mode11b, .mode11g: wifiStandard = "Wi-Fi"
        case .mode11n: wifiStandard = "Wi-Fi 4"
        case .mode11ac: wifiStandard = "Wi-Fi 5"
        case .mode11ax: wifiStandard = "Wi-Fi 6"
        default: wifiStandard = "Wi-Fi"
        }

        return WiFiInfo(
            ssid: interface.ssid(),
            rssi: interface.rssiValue(),
            noise: interface.noiseMeasurement(),
            channel: channel,
            band: band,
            wifiStandard: wifiStandard,
            linkRate: interface.transmitRate()
        )
    }
}
