import Foundation

class PingService {
    private var timer: Timer?
    private let target = "google.com"
    var onPingResult: ((Double?) -> Void)?

    func start() {
        stop()
        ping()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func ping() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let latency = self.executePing()
            DispatchQueue.main.async {
                self.onPingResult?(latency)
            }
        }
    }

    private func executePing() -> Double? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-t", "2", target]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        let pattern = "time=(\\d+\\.?\\d*)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else {
            return nil
        }

        return Double(output[range])
    }
}
