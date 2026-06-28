import Foundation

/// Decodes LC3-encoded audio frames (as streamed by the glasses) into 16-bit
/// PCM samples that the speech recognizer can consume.
///
/// LC3 is the Bluetooth LE Audio codec; iOS does not expose a public LC3
/// decoder, so a real decode requires Google's open-source `liblc3`. The app is
/// designed to compile and run WITHOUT that dependency (you still get BLE
/// connect, mic-enable, and frame reception); once you add `liblc3` the audio
/// pipeline lights up automatically.
///
/// To enable real decoding:
///   1. Add Google's liblc3 (https://github.com/google/liblc3) to the project,
///      e.g. as a Swift Package or a vendored C target that produces a module
///      named `Liblc3` exposing `lc3.h`.
///   2. Rebuild. The `#if canImport(Liblc3)` branch below takes over.
protocol LC3Decoding {
    /// True when this decoder can actually produce audio.
    var isFunctional: Bool { get }
    /// Decode one LC3 payload (which may contain one or more fixed-size frames)
    /// into interleaved Int16 PCM samples.
    func decode(_ payload: Data) -> [Int16]
}

#if canImport(Liblc3)
import Liblc3

/// Real LC3 decoder backed by Google's liblc3.
final class Lc3FrameDecoder: LC3Decoding {
    let isFunctional = true

    private var decoder: lc3_decoder_t?
    private var decoderMemory: UnsafeMutableRawPointer?
    private let frameBytes: Int

    /// `frameBytes` is the encoded size of one LC3 frame as the glasses produce
    /// it. For G1's 16 kHz / 10 ms stream this is commonly 40 bytes; confirm
    /// against your hardware and adjust if needed.
    init(frameBytes: Int = 40) {
        self.frameBytes = frameBytes
        let size = lc3_decoder_size(Int32(GlassesProtocol.frameDurationUs), Int32(GlassesProtocol.sampleRate))
        decoderMemory = malloc(size)
        decoder = lc3_setup_decoder(
            Int32(GlassesProtocol.frameDurationUs),
            Int32(GlassesProtocol.sampleRate),
            Int32(GlassesProtocol.sampleRate),
            decoderMemory
        )
    }

    deinit {
        if let decoderMemory { free(decoderMemory) }
    }

    func decode(_ payload: Data) -> [Int16] {
        guard let decoder, frameBytes > 0 else { return [] }
        var output: [Int16] = []
        var offset = payload.startIndex

        while payload.distance(from: offset, to: payload.endIndex) >= frameBytes {
            let end = payload.index(offset, offsetBy: frameBytes)
            let frame = payload.subdata(in: offset..<end)
            var pcm = [Int16](repeating: 0, count: GlassesProtocol.samplesPerFrame)

            frame.withUnsafeBytes { (inPtr: UnsafeRawBufferPointer) in
                pcm.withUnsafeMutableBytes { (outPtr: UnsafeMutableRawBufferPointer) in
                    _ = lc3_decode(decoder,
                                   inPtr.baseAddress,
                                   Int32(frameBytes),
                                   LC3_PCM_FORMAT_S16,
                                   outPtr.baseAddress,
                                   1)
                }
            }
            output.append(contentsOf: pcm)
            offset = end
        }
        return output
    }
}

typealias DefaultLC3Decoder = Lc3FrameDecoder

#else

/// Placeholder used until `liblc3` is added. It keeps the BLE pipeline fully
/// functional — frames are received and counted — but produces no PCM, so the
/// glasses UI shows the "add liblc3 to enable transcription" hint.
final class NullLC3Decoder: LC3Decoding {
    let isFunctional = false
    func decode(_ payload: Data) -> [Int16] { [] }
}

typealias DefaultLC3Decoder = NullLC3Decoder

#endif
