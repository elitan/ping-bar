import Foundation

class DNSService {
    private let hostname: String

    init(hostname: String = "cloudflare.com") {
        self.hostname = hostname
    }

    func lookup() -> Double? {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var result: UnsafeMutablePointer<addrinfo>?

        let start = CFAbsoluteTimeGetCurrent()
        let status = getaddrinfo(hostname, nil, &hints, &result)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        if let result = result {
            freeaddrinfo(result)
        }

        return status == 0 ? elapsed : nil
    }
}
