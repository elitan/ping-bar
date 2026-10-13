import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage(SettingsKey.showIconMode) private var showIconMode = false
    @AppStorage(SettingsKey.pingInterval) private var pingInterval = 1.0
    @AppStorage(SettingsKey.internetTarget) private var internetTarget = AppSettings.defaultInternetTarget
    @AppStorage(SettingsKey.dnsHostname) private var dnsHostname = AppSettings.defaultDNSHostname
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var internetTargetDraft: String = ""
    @State private var dnsHostnameDraft: String = ""

    var body: some View {
        Form {
            Section {
                Toggle("Show Icon Instead of Ping Time", isOn: $showIconMode)
                Toggle("Launch at Login", isOn: Binding(get: { launchAtLogin }, set: setLaunchAtLogin))

                Picker("Ping Interval", selection: $pingInterval) {
                    ForEach([1.0, 2, 5, 10, 30, 60], id: \.self) { seconds in
                        Text("\(Int(seconds))s").tag(seconds)
                    }
                }
            }

            Section("Ping Targets") {
                TextField("Internet Target", text: $internetTargetDraft, prompt: Text(AppSettings.defaultInternetTarget))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveTargets)

                TextField("DNS Hostname", text: $dnsHostnameDraft, prompt: Text(AppSettings.defaultDNSHostname))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveTargets)

                HStack {
                    Spacer()
                    Button("Save", action: saveTargets)
                        .disabled(internetTargetDraft == internetTarget && dnsHostnameDraft == dnsHostname)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 280)
        .onAppear {
            internetTargetDraft = internetTarget
            dnsHostnameDraft = dnsHostname
        }
    }

    private func saveTargets() {
        func cleaned(_ draft: String, fallback: String) -> String {
            let trimmed = draft.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? fallback : trimmed
        }
        internetTarget = cleaned(internetTargetDraft, fallback: AppSettings.defaultInternetTarget)
        dnsHostname = cleaned(dnsHostnameDraft, fallback: AppSettings.defaultDNSHostname)
        NSApp.keyWindow?.close()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
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
