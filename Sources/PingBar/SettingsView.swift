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
        }
        .formStyle(.grouped)
        .frame(width: 250, height: 80)
    }
}

class SettingsViewModel: ObservableObject {
    @Published var launchAtLogin: Bool = false

    init() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
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
}
