import Foundation

extension Notification.Name {
    static let pingIntervalChanged = Notification.Name("pingIntervalChanged")
    static let pingTargetsChanged = Notification.Name("pingTargetsChanged")
}

enum Defaults {
    static let internetTarget = "1.1.1.1"
    static let dnsHostname = "google.com"
    static let pingInterval: Double = 1.0
}
