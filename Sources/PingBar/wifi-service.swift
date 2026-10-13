import Foundation
import CoreWLAN

struct WiFiInfo: Equatable {
    let ssid: String?
    let rssi: Int
    let noise: Int
    let band: String
    let wifiStandard: String
    let linkRate: Double

    static func current() -> WiFiInfo? {
        guard let interface = CWWiFiClient.shared().interface(), interface.powerOn() else { return nil }

        // 6 GHz reuses channel numbers from the other bands, so ask CoreWLAN for the band directly.
        let channelBand = interface.wlanChannel()?.channelBand
        let band: String
        switch channelBand {
        case .band2GHz: band = "2.4 GHz"
        case .band5GHz: band = "5 GHz"
        case .band6GHz: band = "6 GHz"
        default: band = "?"
        }

        let wifiStandard: String
        switch interface.activePHYMode() {
        case .mode11n: wifiStandard = "Wi-Fi 4"
        case .mode11ac: wifiStandard = "Wi-Fi 5"
        case .mode11ax: wifiStandard = channelBand == .band6GHz ? "Wi-Fi 6E" : "Wi-Fi 6"
        // kCWPHYMode11be (7) isn't in older SDKs.
        case let mode where mode.rawValue == 7: wifiStandard = "Wi-Fi 7"
        default: wifiStandard = "Wi-Fi"
        }

        return WiFiInfo(
            ssid: interface.ssid(),
            rssi: interface.rssiValue(),
            noise: interface.noiseMeasurement(),
            band: band,
            wifiStandard: wifiStandard,
            linkRate: interface.transmitRate()
        )
    }
}
