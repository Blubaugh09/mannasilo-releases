import Foundation
import AVFoundation
import Speech
import Combine

/// Turns a stream of PCM audio (decoded from the glasses' microphone) into live
/// text using Apple's on-device Speech framework. Nothing is sent to Apple's
/// servers when on-device recognition is available.
@MainActor
final class SpeechProcessor: ObservableObject {

    @Published private(set) var transcript: String = ""
    @Published private(set) var isRunning = false
    @Published private(set) var authorizationDenied = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private let inputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: GlassesProtocol.sampleRate,
        channels: GlassesProtocol.channels,
        interleaved: true
    )

    /// Request speech permission up front (call before starting).
    func requestAuthorization() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        authorizationDenied = (status != .authorized)
    }

    func start() {
        guard !isRunning else { return }
        guard recognizer?.isAvailable == true else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in self.transcript = result.bestTranscription.formattedString }
            }
            if error != nil {
                Task { @MainActor in self.stop() }
            }
        }
        isRunning = true
    }

    /// Feed a chunk of Int16 PCM samples (16 kHz mono) from the glasses.
    func appendPCM(_ samples: [Int16]) {
        guard isRunning, let request, let inputFormat, !samples.isEmpty else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: inputFormat,
                                            frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.int16ChannelData {
            samples.withUnsafeBufferPointer { src in
                channel[0].update(from: src.baseAddress!, count: samples.count)
            }
        }
        request.append(buffer)
    }

    func stop() {
        guard isRunning else { return }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRunning = false
    }

    func clear() {
        transcript = ""
    }
}
