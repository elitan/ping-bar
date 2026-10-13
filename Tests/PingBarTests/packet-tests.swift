import Testing
@testable import PingBar

struct ICMPPacketTests {
    @Test func echoRequestHasAValidChecksum() {
        let packet = ICMPPacket.echoRequest(identifier: 0x1234, sequence: 0xABCD, isIPv6: false)
        #expect(packet[0] == 8)
        #expect(Array(packet[4..<8]) == [0x12, 0x34, 0xAB, 0xCD])
        // A packet including its own checksum sums to zero.
        #expect(ICMPPacket.checksum(packet) == 0)
    }

    @Test func ipv6EchoRequestLeavesChecksumToTheKernel() {
        let packet = ICMPPacket.echoRequest(identifier: 1, sequence: 2, isIPv6: true)
        #expect(packet[0] == 128)
        #expect(packet[2] == 0 && packet[3] == 0)
    }

    @Test func matchesIPv4ReplyAfterTheIPHeader() {
        let ipHeader: [UInt8] = [0x45] + [UInt8](repeating: 0, count: 19)
        let reply: [UInt8] = [0, 0, 0, 0, 0x12, 0x34, 0xAB, 0xCD]
        #expect(ICMPPacket.isEchoReply(ipHeader + reply, identifier: 0x1234, sequence: 0xABCD, isIPv6: false))
        #expect(!ICMPPacket.isEchoReply(ipHeader + reply, identifier: 0x1234, sequence: 0xABCE, isIPv6: false))
        #expect(!ICMPPacket.isEchoReply(reply, identifier: 0x1234, sequence: 0xABCD, isIPv6: false))
    }

    @Test func matchesIPv6Reply() {
        let reply: [UInt8] = [129, 0, 0, 0, 0x00, 0x01, 0x00, 0x02]
        #expect(ICMPPacket.isEchoReply(reply, identifier: 1, sequence: 2, isIPv6: true))
        // Our own echo request looped back is not a reply.
        #expect(!ICMPPacket.isEchoReply([128] + reply.dropFirst(), identifier: 1, sequence: 2, isIPv6: true))
    }
}

struct DNSPacketTests {
    @Test func encodesAnAQuery() {
        let packet = DNSPacket.query(id: 0xBEEF, hostname: "a.bc")
        #expect(packet == [
            0xBE, 0xEF, 0x01, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0,
            1, 0x61, 2, 0x62, 0x63, 0,
            0x00, 0x01, 0x00, 0x01,
        ])
    }

    @Test func rejectsInvalidHostnames() {
        #expect(DNSPacket.query(id: 1, hostname: "") == nil)
        #expect(DNSPacket.query(id: 1, hostname: String(repeating: "a", count: 64) + ".com") == nil)
    }

    @Test func acceptsOnlyMatchingSuccessfulResponses() {
        var response: [UInt8] = [0xBE, 0xEF, 0x81, 0x80] + [UInt8](repeating: 0, count: 8)
        #expect(DNSPacket.isSuccessfulResponse(response, id: 0xBEEF))
        #expect(!DNSPacket.isSuccessfulResponse(response, id: 0xBEEE))

        response[3] = 0x83 // NXDOMAIN
        #expect(!DNSPacket.isSuccessfulResponse(response, id: 0xBEEF))
    }
}
