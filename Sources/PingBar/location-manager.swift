import Foundation
import CoreLocation

/// macOS only reveals the WiFi network name to apps with location permission.
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onAuthorizationChanged: (() -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChanged?()
    }
}
