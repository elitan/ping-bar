import Foundation

/// Times a DNS query sent straight to the resolver. Going through `getaddrinfo` would mostly measure
/// the local mDNSResponder cache instead of the network.
enum DNSProbe {
    static func query(_ hostname: String, server: String, timeout: TimeInterval = 2) -> Double? {
        let id = UInt16.random(in: .min ... .max)
        guard let packet = DNSPacket.query(id: id, hostname: hostname),
              let address = SocketAddress.resolve(server, port: 53, numericOnly: true) else { return nil }

        return socketRoundTrip(
            to: address,
            type: SOCK_DGRAM,
            protocol: IPPROTO_UDP,
            packet: packet,
            timeout: timeout
        ) { DNSPacket.isSuccessfulResponse($0, id: id) }
    }
}

enum DNSPacket {
    /// Builds a recursive query for the A record of `hostname`, or nil if it isn't a valid DNS name.
    static func query(id: UInt16, hostname: String) -> [UInt8]? {
        var bytes: [UInt8] = [
            UInt8(id >> 8), UInt8(id & 0xFF),
            0x01, 0x00, // recursion desired
            0x00, 0x01, // one question
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]
        let labels = hostname.split(separator: ".")
        guard !labels.isEmpty else { return nil }
        for label in labels {
            let utf8 = Array(label.utf8)
            guard (1...63).contains(utf8.count) else { return nil }
            bytes.append(UInt8(utf8.count))
            bytes += utf8
        }
        bytes += [0x00, 0x00, 0x01, 0x00, 0x01] // root, type A, class IN
        return bytes
    }

    static func isSuccessfulResponse(_ packet: [UInt8], id: UInt16) -> Bool {
        guard packet.count >= 12 else { return false }
        let isResponse = packet[2] & 0x80 != 0
        let responseCode = packet[3] & 0x0F
        return packet[0] == UInt8(id >> 8) && packet[1] == UInt8(id & 0xFF) && isResponse && responseCode == 0
    }
}
