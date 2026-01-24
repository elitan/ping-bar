import SwiftUI

struct MetricRowView: View {
    let label: String
    let value: String
    let color: Color
    let history: [Double?]
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(color)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 100, alignment: .leading)

            SparklineView(values: history, color: color)
        }
        .padding(.vertical, 4)
    }
}
