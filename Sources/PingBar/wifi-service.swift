import Foundation
import CoreWLAN

struct WiFiInfo {
    let ssid: String?
    let rssi: Int
    let noise: Int
    let channel: Int
    let band: String
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
        case 36...: band = "5 GHz"
        default: band = "Unknown"
        }

        return WiFiInfo(
            ssid: interface.ssid(),
            rssi: interface.rssiValue(),
            noise: interface.noiseMeasurement(),
            channel: channel,
            band: band,
            linkRate: interface.transmitRate()
        )
    }
}
