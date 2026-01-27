import Foundation

class MetricHistory {
    private var buffer: [Double?]
    private var index = 0
    private var isFull = false
    let capacity: Int

    init(capacity: Int = 60) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }

    func add(_ value: Double?) {
        buffer[index] = value
        index = (index + 1) % capacity
        if index == 0 { isFull = true }
    }

    var values: [Double?] {
        if isFull {
            return Array(buffer[index...]) + Array(buffer[..<index])
        } else {
            return Array(buffer[..<index])
        }
    }

    var nonNilValues: [Double] {
        values.compactMap { $0 }
    }

    var latest: Double? {
        if index == 0 && !isFull { return nil }
        let lastIndex = index == 0 ? capacity - 1 : index - 1
        return buffer[lastIndex]
    }

    var average: Double? {
        let vals = nonNilValues
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    var jitter: Double? {
        let vals = nonNilValues
        guard vals.count > 1, let avg = average else { return nil }
        let deviations = vals.map { abs($0 - avg) }
        return deviations.reduce(0, +) / Double(deviations.count)
    }

    var lossPercentage: Double {
        let total = isFull ? capacity : index
        guard total > 0 else { return 0 }
        let nilCount = values.filter { $0 == nil }.count
        return Double(nilCount) / Double(total) * 100
    }

    var recentWeightedAverage: Double? {
        let window = 10
        let alpha = 0.2
        let vals = values
        let recent = vals.suffix(window)
        var ewma: Double?
        for sample in recent {
            guard let s = sample else { continue }
            if let prev = ewma {
                ewma = alpha * s + (1.0 - alpha) * prev
            } else {
                ewma = s
            }
        }
        return ewma
    }

    func clear() {
        buffer = Array(repeating: nil, count: capacity)
        index = 0
        isFull = false
    }
}
