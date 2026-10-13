import Foundation

enum SettingsKey {
    static let internetTarget = "internetTarget"
    static let dnsHostname = "dnsHostname"
    static let pingInterval = "pingInterval"
    static let showIconMode = "showIconMode"
}

struct AppSettings: Equatable {
    static let defaultInternetTarget = "1.1.1.1"
    static let defaultDNSHostname = "google.com"

    var internetTarget: String
    var dnsHostname: String
    var pingInterval: Double
    var showIconMode: Bool

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.internetTarget: defaultInternetTarget,
            SettingsKey.dnsHostname: defaultDNSHostname,
            SettingsKey.pingInterval: 1.0,
            SettingsKey.showIconMode: false,
        ])
    }

    static var current: AppSettings {
        let defaults = UserDefaults.standard
        // Older versions could store an empty string to mean "use the default".
        func string(_ key: String, fallback: String) -> String {
            let value = defaults.string(forKey: key) ?? ""
            return value.isEmpty ? fallback : value
        }
        return AppSettings(
            internetTarget: string(SettingsKey.internetTarget, fallback: defaultInternetTarget),
            dnsHostname: string(SettingsKey.dnsHostname, fallback: defaultDNSHostname),
            pingInterval: max(defaults.double(forKey: SettingsKey.pingInterval), 1),
            showIconMode: defaults.bool(forKey: SettingsKey.showIconMode)
        )
    }
}
