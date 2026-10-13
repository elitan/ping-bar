import Testing
@testable import PingBar

struct MetricHistoryTests {
    private func history(_ values: [Double?]) -> MetricHistory {
        var history = MetricHistory()
        values.forEach { history.add($0) }
        return history
    }

    @Test func keepsOnlyTheLastSixtySamples() {
        let history = history((1...70).map(Double.init))
        #expect(history.values.count == MetricHistory.capacity)
        #expect(history.values.first == 11)
        #expect(history.latest == 70)
    }

    @Test func latestIsNilAfterAFailedProbe() {
        #expect(history([10, nil]).latest == nil)
        #expect(MetricHistory().latest == nil)
    }

    @Test func lossCountsFailedProbes() {
        #expect(history([10, nil, 20, nil]).lossPercentage == 50)
        #expect(MetricHistory().lossPercentage == 0)
    }

    @Test func jitterIsMeanDifferenceBetweenConsecutiveSamples() {
        #expect(history([10, 20, 10, 20]).jitter == 10)
        // Pairs that straddle a failed probe are skipped.
        #expect(history([10, 20, nil, 100, 110]).jitter == 10)
        #expect(history([10]).jitter == nil)
    }

    @Test func smoothedWeighsRecentSamples() {
        #expect(history([100]).smoothed == 100)
        // 0.2 * 200 + 0.8 * 100
        #expect(history([100, 200]).smoothed == 120)
        #expect(history([nil, nil]).smoothed == nil)
    }
}
