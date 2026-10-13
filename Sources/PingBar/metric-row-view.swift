import SwiftUI

struct MetricRowView: View {
    let label: String
    let history: MetricHistory
    var showsJitter = false

    var body: some View {
        let color = Color(nsColor: latencyColor(history))

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatLatency(history.latest))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(color)
                    if showsJitter, let jitter = history.jitter {
                        Text("±\(Int(jitter.rounded()))ms")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 100, alignment: .leading)

            SparklineView(values: history.values, color: color)
        }
        .padding(.vertical, 4)
    }
}
