import Foundation

struct SocketAddress {
    var storage = sockaddr_storage()
    var length: socklen_t = 0
    var family: Int32 { Int32(storage.ss_family) }

    /// Resolves `host` (a hostname or a numeric IPv4/IPv6 address) to its first address.
    static func resolve(_ host: String, port: UInt16 = 0, numericOnly: Bool = false) -> SocketAddress? {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_DGRAM
        if numericOnly { hints.ai_flags = AI_NUMERICHOST }

        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, port == 0 ? nil : String(port), &hints, &result) == 0, let info = result else {
            return nil
        }
        defer { freeaddrinfo(result) }

        var address = SocketAddress()
        address.length = info.pointee.ai_addrlen
        withUnsafeMutableBytes(of: &address.storage) { buffer in
            buffer.copyMemory(from: UnsafeRawBufferPointer(start: info.pointee.ai_addr, count: Int(info.pointee.ai_addrlen)))
        }
        return address
    }
}

/// Sends `packet` from a new socket and waits for a datagram that `isReply` accepts.
/// Returns the round-trip time in milliseconds, or nil on error or timeout.
func socketRoundTrip(
    to address: SocketAddress,
    type: Int32,
    protocol proto: Int32,
    packet: [UInt8],
    timeout: TimeInterval,
    isReply: ([UInt8]) -> Bool
) -> Double? {
    let fd = socket(address.family, type, proto)
    guard fd >= 0 else { return nil }
    defer { close(fd) }

    var receiveTimeout = timeval(tv_sec: Int(timeout), tv_usec: Int32(timeout.truncatingRemainder(dividingBy: 1) * 1_000_000))
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &receiveTimeout, socklen_t(MemoryLayout<timeval>.size))

    let start = DispatchTime.now()
    func elapsed() -> Double { Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000 }

    var destination = address.storage
    let sent = withUnsafePointer(to: &destination) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            sendto(fd, packet, packet.count, 0, $0, address.length)
        }
    }
    guard sent == packet.count else { return nil }

    // The socket can also receive unrelated datagrams (other pings, ICMPv6 neighbor discovery), so keep
    // reading until the matching reply arrives or the overall deadline passes.
    var buffer = [UInt8](repeating: 0, count: 1500)
    while elapsed() < timeout * 1000 {
        let count = recv(fd, &buffer, buffer.count, 0)
        if count < 0 {
            if errno == EINTR { continue }
            return nil
        }
        if isReply(Array(buffer[..<count])) { return elapsed() }
    }
    return nil
}
