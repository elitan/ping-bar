import Cocoa
import SwiftUI

func latencyColor(_ ms: Double?) -> NSColor {
    guard let ms = ms else { return .systemRed }
    let ratio = min(1.0, ms / 200.0)
    let hue = (1.0 - ratio) * 0.33
    return NSColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1.0)
}

func latencySwiftUIColor(_ ms: Double?) -> Color {
    guard let ms = ms else { return .red }
    let ratio = min(1.0, ms / 200.0)
    let hue = (1.0 - ratio) * 0.33
    return Color(hue: hue, saturation: 0.8, brightness: 0.9)
}
