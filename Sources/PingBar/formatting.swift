import Cocoa

func formatLatency(_ ms: Double?) -> String {
    guard let ms else { return "---" }
    if ms >= 1000 { return String(format: "%.1fs", ms / 1000) }
    return "\(Int(ms.rounded()))ms"
}

/// Red when the last probe failed, otherwise a green-to-red gradient over 0–200 ms of smoothed latency.
func latencyColor(_ history: MetricHistory) -> NSColor {
    guard history.latest != nil, let ms = history.smoothed else { return .systemRed }
    let ratio = min(1.0, ms / 200.0)
    return NSColor(hue: (1.0 - ratio) * 0.33, saturation: 0.8, brightness: 0.9, alpha: 1.0)
}

func signalColor(_ rssi: Int) -> NSColor {
    switch rssi {
    case (-50)...: return .systemGreen
    case (-70)...: return .systemOrange
    default: return .systemRed
    }
}

func lossColor(_ loss: Double) -> NSColor {
    switch loss {
    case 0: return .systemGreen
    case ..<5: return .systemOrange
    default: return .systemRed
    }
}
