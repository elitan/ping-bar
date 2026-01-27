import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var viewModel: DiagnosticsViewModel
    var onSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            wifiSection
            Divider().padding(.vertical, 8)
            routerSection
            Divider().padding(.vertical, 8)
            internetSection
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

            if let wifi = viewModel.wifiInfo {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isCaptivePortal ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    if let ssid = wifi.ssid {
                        Text(ssid)
                            .font(.system(size: 14, weight: .medium))
                    } else {
                        Button("Grant Permission") {
                            viewModel.requestLocationPermission()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Spacer()
                    Text(wifi.band)
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                if viewModel.isCaptivePortal {
                    captivePortalWarning
                }

                HStack(spacing: 16) {
                    wifiMetric("Signal", "\(wifi.rssi) dBm", viewModel.colorForSignal(wifi.rssi))
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

    private var captivePortalWarning: some View {
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
                viewModel.openCaptivePortalLogin()
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

    private var routerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionHeader("Router")
                Spacer()
                if let gateway = viewModel.gatewayIP {
                    Text(gateway)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            MetricRowView(
                label: "Latency",
                value: formatLatency(viewModel.routerLatency),
                color: viewModel.colorForPing(viewModel.routerLatency, smoothed: viewModel.routerSmoothed),
                history: viewModel.routerHistory,
                subtitle: formatJitter(viewModel.routerJitter)
            )

            lossRow(viewModel.routerLoss)
        }
    }

    private var internetSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionHeader("Internet")
                Spacer()
                Text(viewModel.internetTargetLabel)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            MetricRowView(
                label: "Latency",
                value: formatLatency(viewModel.internetLatency),
                color: viewModel.colorForPing(viewModel.internetLatency, smoothed: viewModel.internetSmoothed),
                history: viewModel.internetHistory,
                subtitle: formatJitter(viewModel.internetJitter)
            )

            lossRow(viewModel.internetLoss)
        }
    }

    private var dnsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionHeader("DNS")
                Spacer()
                Text(viewModel.dnsServerIP ?? "---")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            MetricRowView(
                label: "Lookup",
                value: formatLatency(viewModel.dnsLatency),
                color: viewModel.colorForPing(viewModel.dnsLatency, smoothed: viewModel.dnsSmoothed),
                history: viewModel.dnsHistory
            )
        }
    }

    private var footerSection: some View {
        HStack {
            Button(viewModel.isRunning ? "Stop" : "Start") {
                if viewModel.isRunning {
                    viewModel.stop()
                } else {
                    viewModel.start()
                }
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Settings") {
                onSettings()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Button("Quit") {
                onQuit()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }

    private func lossRow(_ loss: Double) -> some View {
        HStack {
            Text("Loss")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(String(format: "%.1f%%", loss))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(viewModel.colorForLoss(loss))
        }
    }

    private func formatLatency(_ ms: Double?) -> String {
        guard let ms = ms else { return "---" }
        if ms >= 1000 {
            return String(format: "%.1fs", ms / 1000)
        }
        return "\(Int(ms.rounded()))ms"
    }

    private func formatJitter(_ jitter: Double?) -> String? {
        guard let j = jitter else { return nil }
        return "±\(Int(j.rounded()))ms"
    }
}
