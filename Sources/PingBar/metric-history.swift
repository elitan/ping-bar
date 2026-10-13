import Foundation

/// The last 60 samples of one metric; nil samples are failed probes.
struct MetricHistory: Equatable {
    static let capacity = 60

    private(set) var values: [Double?] = []

    mutating func add(_ value: Double?) {
        values.append(value)
        if values.count > Self.capacity { values.removeFirst() }
    }

    var latest: Double? { values.last ?? nil }

    var lossPercentage: Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.filter { $0 == nil }.count) / Double(values.count) * 100
    }

    /// Mean difference between consecutive successful samples (RFC 3550-style jitter).
    var jitter: Double? {
        let differences = zip(values, values.dropFirst()).compactMap { previous, current -> Double? in
            guard let previous, let current else { return nil }
            return abs(current - previous)
        }
        guard !differences.isEmpty else { return nil }
        return differences.reduce(0, +) / Double(differences.count)
    }

    /// Exponentially weighted average of the last 10 samples, so colors don't flicker on single spikes.
    var smoothed: Double? {
        let alpha = 0.2
        return values.suffix(10).compactMap { $0 }.reduce(nil as Double?) { average, sample in
            average.map { alpha * sample + (1 - alpha) * $0 } ?? sample
        }
    }
}
