import Foundation
import CoreBluetooth

/// Bluetooth Low Energy protocol constants for Even Realities smart glasses.
///
/// IMPORTANT — read before changing:
/// The Even Realities mic stream is **not** an officially published API. These
/// values are the community-reverse-engineered protocol for the Even Realities
/// **G1**, which the newer **G2** is expected to closely follow. Everything that
/// might differ between G1 and G2 is isolated here as a named constant so you can
/// adjust a single value against the real hardware rather than hunting through
/// the manager. Capture the glasses' traffic with a BLE sniffer (e.g. nRF
/// Connect) and update `nusService`, the characteristic UUIDs, or the command
/// bytes below if your G2 differs.
enum GlassesProtocol {

    // MARK: Advertised name
    //
    // G1 advertises as "Even G1_<n>_L_..." / "Even G1_<n>_R_..." (left & right
    // arms are separate peripherals). G2 is expected to use an "Even" prefix
    // too. We match loosely so either generation is discoverable.
    static let namePrefix = "Even"

    static func side(for name: String?) -> Side {
        guard let name else { return .unknown }
        let upper = name.uppercased()
        if upper.contains("_L_") || upper.hasSuffix("_L") || upper.contains(" L ") { return .left }
        if upper.contains("_R_") || upper.hasSuffix("_R") || upper.contains(" R ") { return .right }
        return .unknown
    }

    enum Side: String { case left = "Left", right = "Right", unknown = "Glasses" }

    // MARK: Nordic UART Service (NUS)
    //
    // The glasses expose a standard Nordic UART Service. We write commands to the
    // TX characteristic and receive notifications (including audio) on RX.
    static let nusService   = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let nusTXWrite   = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // app → glasses
    static let nusRXNotify  = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // glasses → app

    // MARK: Command op-codes (app → glasses)
    //
    // 0x0E = microphone control on G1: payload 0x01 enables the mic, 0x00 disables.
    static let cmdMicControl: UInt8 = 0x0E
    static let micEnablePayload: UInt8 = 0x01
    static let micDisablePayload: UInt8 = 0x00

    static func micEnableCommand() -> Data { Data([cmdMicControl, micEnablePayload]) }
    static func micDisableCommand() -> Data { Data([cmdMicControl, micDisablePayload]) }

    // Periodic heartbeat keeps the link alive on some firmware. 0x25 is the G1
    // heartbeat op-code; the trailing bytes are a length/sequence placeholder.
    static func heartbeatCommand(sequence: UInt8) -> Data {
        Data([0x25, 0x06, 0x00, sequence, 0x04, 0x01])
    }

    // MARK: Incoming op-codes (glasses → app, first byte of an RX notification)
    //
    // 0xF1 = a frame of microphone audio. Layout on G1:
    //   byte 0:      0xF1  (audio op-code)
    //   byte 1:      sequence number
    //   bytes 2...n: LC3-encoded audio payload
    static let evtAudioFrame: UInt8 = 0xF1

    /// Strip the 2-byte header off an audio notification, returning the raw LC3
    /// payload (or nil if this notification isn't an audio frame).
    static func audioPayload(from notification: Data) -> Data? {
        guard notification.count > 2, notification[notification.startIndex] == evtAudioFrame else {
            return nil
        }
        return notification.subdata(in: notification.index(notification.startIndex, offsetBy: 2)..<notification.endIndex)
    }

    // MARK: Audio format
    //
    // G1 streams LC3 at 16 kHz mono, 10 ms frames (160 samples/frame). These feed
    // both the LC3 decoder and the speech recognizer's expected input format.
    static let sampleRate: Double = 16_000
    static let channels: UInt32 = 1
    static let frameDurationUs: Int = 10_000     // 10 ms
    static let samplesPerFrame: Int = 160        // 16000 * 0.01
}
