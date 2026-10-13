import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var diagnostics: Diagnostics
    var onSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            wifiSection
            Divider().padding(.vertical, 8)
            latencySection("Router", detail: diagnostics.gatewayIP, history: diagnostics.router)
            Divider().padding(.vertical, 8)
            latencySection("Internet", detail: diagnostics.settings.internetTarget, history: diagnostics.internet)
            Divider().padding(.vertical, 8)
            dnsSection
            Divider().padding(.vertical, 8)
            footerSection
        }
        .padding(16)
        .frame(width: 320)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var wifiSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("WiFi")

            if let wifi = diagnostics.wifi {
                HStack(spacing: 6) {
                    Circle()
                        .fill(diagnostics.captivePortalURL == nil ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    if let ssid = wifi.ssid {
                        Text(ssid)
                            .font(.system(size: 14, weight: .medium))
                    } else {
                        Button("Grant Permission") {
                            diagnostics.requestLocationPermission()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Spacer()
                    Text("\(wifi.wifiStandard) · \(wifi.band)")
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                if let loginURL = diagnostics.captivePortalURL {
                    captivePortalWarning(loginURL)
                }

                HStack(spacing: 16) {
                    wifiMetric("Signal", "\(wifi.rssi) dBm", Color(nsColor: signalColor(wifi.rssi)))
                    wifiMetric("Noise", "\(wifi.noise) dBm", .secondary)
                    wifiMetric("Rate", "\(Int(wifi.linkRate)) Mbps", .primary)
                }
            } else {
                Text("Not connected")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func captivePortalWarning(_ loginURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Captive Portal Detected")
                    .font(.system(size: 12, weight: .semibold))
            }
            Text("This network requires login. Open a browser to authenticate.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Button {
                NSWorkspace.shared.open(loginURL)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.square")
                    Text("Open Login Page")
                }
                .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
    }

    private func wifiMetric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
    }

    private func latencySection(_ title: String, detail: String?, history: MetricHistory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(title, detail: detail)
            MetricRowView(label: "Latency", history: history, showsJitter: true)
            HStack {
                Text("Loss")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f%%", history.lossPercentage))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(nsColor: lossColor(history.lossPercentage)))
            }
        }
    }

    private var dnsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("DNS", detail: diagnostics.dnsServerIP ?? "---")
            MetricRowView(label: "Lookup", history: diagnostics.dns)
        }
    }

    private var footerSection: some View {
        HStack {
            Button(diagnostics.isRunning ? "Stop" : "Start") {
                diagnostics.isRunning ? diagnostics.stop() : diagnostics.start()
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Settings", action: onSettings)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

            Button("Quit", action: onQuit)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
        }
    }

    private func sectionHeader(_ title: String, detail: String? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}
