import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var internetTargetDraft: String = ""
    @State private var dnsHostnameDraft: String = ""
    @State private var targetsChanged = false

    var body: some View {
        Form {
            Section {
                Toggle("Show Icon Instead of Ping Time", isOn: Binding(
                    get: { viewModel.showIconMode },
                    set: { viewModel.setShowIconMode($0) }
                ))

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

            Section("Ping Targets") {
                TextField("Internet Target", text: $internetTargetDraft, prompt: Text("1.1.1.1"))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveTargets() }
                    .onChange(of: internetTargetDraft) { _ in updateChanged() }

                TextField("DNS Hostname", text: $dnsHostnameDraft, prompt: Text("google.com"))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveTargets() }
                    .onChange(of: dnsHostnameDraft) { _ in updateChanged() }

                HStack {
                    Spacer()
                    Button("Save") { saveTargets() }
                        .disabled(!targetsChanged)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 280)
        .onAppear {
            internetTargetDraft = viewModel.internetTarget
            dnsHostnameDraft = viewModel.dnsHostname
        }
    }

    private func updateChanged() {
        targetsChanged = internetTargetDraft != viewModel.internetTarget
            || dnsHostnameDraft != viewModel.dnsHostname
    }

    private func saveTargets() {
        viewModel.setInternetTarget(internetTargetDraft.trimmingCharacters(in: .whitespaces))
        viewModel.setDnsHostname(dnsHostnameDraft.trimmingCharacters(in: .whitespaces))
        targetsChanged = false
        NSApp.keyWindow?.close()
    }
}

class SettingsViewModel: ObservableObject {
    @Published var launchAtLogin: Bool = false
    @Published var pingInterval: Double = 1.0
    @Published var internetTarget: String = ""
    @Published var dnsHostname: String = ""
    @Published var showIconMode: Bool = false

    init() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        let stored = UserDefaults.standard.double(forKey: "pingInterval")
        pingInterval = stored > 0 ? stored : Defaults.pingInterval

        internetTarget = UserDefaults.standard.string(forKey: "internetTarget") ?? ""
        dnsHostname = UserDefaults.standard.string(forKey: "dnsHostname") ?? ""
        showIconMode = UserDefaults.standard.bool(forKey: "showIconMode")
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
        NotificationCenter.default.post(name: .pingIntervalChanged, object: nil)
    }

    func setInternetTarget(_ value: String) {
        internetTarget = value
        UserDefaults.standard.set(value, forKey: "internetTarget")
        NotificationCenter.default.post(name: .pingTargetsChanged, object: nil)
    }

    func setDnsHostname(_ value: String) {
        dnsHostname = value
        UserDefaults.standard.set(value, forKey: "dnsHostname")
        NotificationCenter.default.post(name: .pingTargetsChanged, object: nil)
    }

    func setShowIconMode(_ enabled: Bool) {
        showIconMode = enabled
        UserDefaults.standard.set(enabled, forKey: "showIconMode")
        NotificationCenter.default.post(name: .displayModeChanged, object: nil)
    }
}
