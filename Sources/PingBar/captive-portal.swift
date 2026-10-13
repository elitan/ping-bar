import Foundation

enum CaptivePortal {
    private static let testURL = URL(string: "http://captive.apple.com/hotspot-detect.html")!

    /// Returns the login page if the network intercepts Apple's connectivity check, otherwise nil
    /// (including when there's no connection at all).
    static func loginURL() async -> URL? {
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return nil }

        let body = String(decoding: data, as: UTF8.self)
        if http.statusCode == 200 && body.contains("Success") { return nil }
        return http.url ?? testURL
    }
}
