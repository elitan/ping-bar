import Foundation

/// Pings over an unprivileged ICMP datagram socket, so no `/sbin/ping` process is spawned.
enum ICMPPing {
    static func ping(_ host: String, timeout: TimeInterval = 2) -> Double? {
        guard let address = SocketAddress.resolve(host) else { return nil }
        let isIPv6 = address.family == AF_INET6
        let identifier = UInt16.random(in: .min ... .max)
        let sequence = UInt16.random(in: .min ... .max)

        return socketRoundTrip(
            to: address,
            type: SOCK_DGRAM,
            protocol: isIPv6 ? IPPROTO_ICMPV6 : IPPROTO_ICMP,
            packet: ICMPPacket.echoRequest(identifier: identifier, sequence: sequence, isIPv6: isIPv6),
            timeout: timeout
        ) { ICMPPacket.isEchoReply($0, identifier: identifier, sequence: sequence, isIPv6: isIPv6) }
    }
}

enum ICMPPacket {
    static func echoRequest(identifier: UInt16, sequence: UInt16, isIPv6: Bool) -> [UInt8] {
        var bytes: [UInt8] = [isIPv6 ? 128 : 8, 0, 0, 0]
        bytes += bigEndianBytes(identifier) + bigEndianBytes(sequence)
        bytes += [UInt8](repeating: 0, count: 56)
        // The kernel fills in the ICMPv6 checksum itself; ICMPv4 needs it computed here.
        if !isIPv6 {
            let sum = checksum(bytes)
            bytes[2] = UInt8(sum >> 8)
            bytes[3] = UInt8(sum & 0xFF)
        }
        return bytes
    }

    /// Datagram ICMPv4 sockets on macOS deliver the IP header too; ICMPv6 sockets don't.
    static func isEchoReply(_ packet: [UInt8], identifier: UInt16, sequence: UInt16, isIPv6: Bool) -> Bool {
        var offset = 0
        if !isIPv6 {
            guard let first = packet.first else { return false }
            offset = Int(first & 0x0F) * 4
            guard offset >= 20 else { return false }
        }
        guard packet.count >= offset + 8 else { return false }
        return packet[offset] == (isIPv6 ? 129 : 0)
            && packet[offset + 1] == 0
            && Array(packet[offset + 4 ..< offset + 6]) == bigEndianBytes(identifier)
            && Array(packet[offset + 6 ..< offset + 8]) == bigEndianBytes(sequence)
    }

    static func checksum(_ bytes: [UInt8]) -> UInt16 {
        var sum: UInt32 = 0
        var index = 0
        while index + 1 < bytes.count {
            sum += UInt32(bytes[index]) << 8 | UInt32(bytes[index + 1])
            index += 2
        }
        if index < bytes.count { sum += UInt32(bytes[index]) << 8 }
        while sum >> 16 != 0 { sum = (sum & 0xFFFF) + (sum >> 16) }
        return ~UInt16(sum)
    }

    private static func bigEndianBytes(_ value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }
}
