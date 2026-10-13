import Foundation
import SystemConfiguration

/// Reads the default gateway and DNS server from configd, the same source `route` and `scutil` use.
enum NetworkConfig {
    private static let store = SCDynamicStoreCreate(nil, "PingBar" as CFString, nil, nil)

    static var gateway: String? {
        value(for: "State:/Network/Global/IPv4")?["Router"] as? String
    }

    static var dnsServer: String? {
        (value(for: "State:/Network/Global/DNS")?["ServerAddresses"] as? [String])?.first
    }

    private static func value(for key: String) -> [String: Any]? {
        SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any]
    }
}
