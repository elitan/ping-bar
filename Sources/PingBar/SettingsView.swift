import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { viewModel.setLaunchAtLogin($0) }
            ))

            Picker("Ping Interval", selection: Binding(
                get: { viewModel.pingInterval },
                set: { viewModel.setPingInterval($0) }
            )) {
                Text("1s").tag(1.0)
                Text("2s").tag(2.0)
                Text("5s").tag(5.0)
                Text("10s").tag(10.0)
                Text("30s").tag(30.0)
                Text("60s").tag(60.0)
            }
        }
        .formStyle(.grouped)
        .frame(width: 250, height: 140)
    }
}

class SettingsViewModel: ObservableObject {
    @Published var launchAtLogin: Bool = false
    @Published var pingInterval: Double = 1.0

    init() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        let stored = UserDefaults.standard.double(forKey: "pingInterval")
        pingInterval = stored > 0 ? stored : 1.0
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                launchAtLogin = enabled
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }

    func setPingInterval(_ interval: Double) {
        pingInterval = interval
        UserDefaults.standard.set(interval, forKey: "pingInterval")
        NotificationCenter.default.post(name: Notification.Name("pingIntervalChanged"), object: nil)
    }
}
