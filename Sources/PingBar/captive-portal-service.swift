import Foundation
import AppKit

class CaptivePortalService {
    private let testURL = URL(string: "http://captive.apple.com/hotspot-detect.html")!

    func check(completion: @escaping (CaptivePortalStatus) -> Void) {
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.noInternet(error.localizedDescription))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data,
                      let body = String(data: data, encoding: .utf8) else {
                    completion(.noInternet("No response"))
                    return
                }

                if httpResponse.statusCode == 200 && body.contains("Success") {
                    completion(.connected)
                } else {
                    let loginURL = httpResponse.url ?? self.testURL
                    completion(.captivePortal(loginURL))
                }
            }
        }
        task.resume()
    }

    func openLoginPage(url: URL) {
        NSWorkspace.shared.open(url)
    }
}

enum CaptivePortalStatus: Equatable {
    case unknown
    case connected
    case captivePortal(URL)
    case noInternet(String)
}
