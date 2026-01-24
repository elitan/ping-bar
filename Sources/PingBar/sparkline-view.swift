import SwiftUI

struct SparklineView: View {
    let values: [Double?]
    let color: Color
    let height: CGFloat

    init(values: [Double?], color: Color = .blue, height: CGFloat = 24) {
        self.values = values
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            let nonNilValues = values.compactMap { $0 }
            if nonNilValues.count > 1 {
                let minVal = nonNilValues.min() ?? 0
                let maxVal = nonNilValues.max() ?? 1
                let range = max(maxVal - minVal, 1)

                Path { path in
                    let width = geometry.size.width
                    let stepX = width / CGFloat(max(values.count - 1, 1))

                    var started = false
                    for (index, value) in values.enumerated() {
                        guard let val = value else { continue }
                        let x = CGFloat(index) * stepX
                        let normalizedY = (val - minVal) / range
                        let y = geometry.size.height - (CGFloat(normalizedY) * geometry.size.height * 0.8 + geometry.size.height * 0.1)

                        if !started {
                            path.move(to: CGPoint(x: x, y: y))
                            started = true
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 1.5)
            } else {
                Color.clear
            }
        }
        .frame(height: height)
    }
}
