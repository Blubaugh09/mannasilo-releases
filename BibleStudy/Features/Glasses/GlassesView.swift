import SwiftUI
import SwiftData

/// Connect the Even Realities glasses and process their microphone directly —
/// scan, connect, enable the mic, and watch a live transcript that you can save
/// as a note or hand off to Claude.
struct GlassesView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var glasses: GlassesManager

    @Query(sort: \ReadingPosition.updatedAt, order: .reverse) private var positions: [ReadingPosition]

    @State private var askSheet: AskSeed?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    statusCard

                    if let error = glasses.lastError {
                        ErrorBanner(message: error, onDismiss: nil)
                    }

                    if !glasses.decoderFunctional {
                        decoderHint
                    }

                    switch glasses.state {
                    case .listening:
                        transcriptSection
                    case .connected:
                        connectedControls
                    default:
                        scanSection
                    }
                }
                .padding(Theme.Space.l)
            }
            .navigationTitle("Glasses")
            .background(Theme.background(scheme))
            .sheet(item: $askSheet) { seed in
                NavigationStack {
                    AskConversationView(seed: seed)
                        .navigationTitle("Ask from transcript")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    // MARK: Status

    private var statusCard: some View {
        Card {
            HStack(spacing: Theme.Space.m) {
                Image(systemName: "eyeglasses")
                    .font(.system(size: 28))
                    .foregroundStyle(settings.accent.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.primaryText(scheme))
                    Text(statusSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
                Spacer()
                if glasses.state == .scanning || glasses.state == .connecting {
                    ProgressView()
                }
            }
        }
    }

    private var statusTitle: String {
        switch glasses.state {
        case .poweredOff:   return "Bluetooth off"
        case .unauthorized: return "Bluetooth not allowed"
        case .idle:         return "Not connected"
        case .scanning:     return "Scanning\u{2026}"
        case .connecting:   return "Connecting\u{2026}"
        case .connected:    return "Connected"
        case .listening:    return "Listening"
        }
    }

    private var statusSubtitle: String {
        switch glasses.state {
        case .poweredOff:   return "Turn on Bluetooth to use your glasses."
        case .unauthorized: return "Allow Bluetooth for this app in Settings."
        case .idle:         return "Scan to find your Even Realities glasses."
        case .scanning:     return "Looking for nearby glasses."
        case .connecting:   return "Pairing with your glasses."
        case .connected:    return glasses.connectedNames.joined(separator: ", ")
        case .listening:    return "\(glasses.framesReceived) audio frames received"
        }
    }

    // MARK: Scan

    private var scanSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            PrimaryButton(
                title: glasses.state == .scanning ? "Stop scanning" : "Scan for glasses",
                systemImage: "dot.radiowaves.left.and.right"
            ) {
                if glasses.state == .scanning { glasses.stopScanning() } else { glasses.startScanning() }
            }

            if !glasses.discovered.isEmpty {
                SectionHeader(title: "Found", systemImage: "antenna.radiowaves.left.and.right")
                ForEach(glasses.discovered) { device in
                    Button { glasses.connect(device) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.primaryText(scheme))
                                Text("\(device.side.rawValue) \u{00B7} \(device.rssi) dBm")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.secondaryText(scheme))
                            }
                            Spacer()
                            Image(systemName: "link").foregroundStyle(settings.accent.color)
                        }
                        .padding(Theme.Space.m)
                        .background(Theme.secondaryBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Connected

    private var connectedControls: some View {
        VStack(spacing: Theme.Space.m) {
            PrimaryButton(title: "Start listening", systemImage: "mic.fill") {
                Task { await glasses.startListening() }
            }
            SecondaryButton(title: "Disconnect", systemImage: "xmark") {
                glasses.disconnect()
            }
        }
    }

    // MARK: Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            SectionHeader(title: "Live transcript", systemImage: "waveform")
            TranscriptView(speech: glasses.speech)

            HStack {
                SecondaryButton(title: "Stop", systemImage: "stop.fill") {
                    glasses.stopListening()
                }
            }

            let transcript = glasses.speech.transcript
            if !transcript.isEmpty {
                HStack {
                    SecondaryButton(title: "Save as note", systemImage: "note.text") {
                        saveTranscriptAsNote(transcript)
                    }
                    SecondaryButton(title: "Ask Claude", systemImage: "sparkles") {
                        askSheet = AskSeed(initialText: transcript)
                    }
                }
            }
        }
    }

    private var decoderHint: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Label("Audio decoding not enabled", systemImage: "info.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(settings.accent.color)
                Text("""
                The app connects to the glasses and receives their microphone audio, but turning \
                that audio into text needs the LC3 codec. Add Google's liblc3 to the project (see \
                LC3Decoder.swift) to enable live transcription.
                """)
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText(scheme))
            }
        }
    }

    private func saveTranscriptAsNote(_ transcript: String) {
        let ref = positions.first?.reference ?? .defaultStart
        let note = StudyNote(
            title: "From glasses",
            body: transcript,
            bookID: ref.bookID,
            chapter: ref.chapter,
            verse: 0
        )
        modelContext.insert(note)
        try? modelContext.save()
    }
}

/// Small observer view so SwiftUI re-renders as the speech transcript updates.
private struct TranscriptView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject var speech: SpeechProcessor

    var body: some View {
        Card {
            if speech.transcript.isEmpty {
                Text(speech.isRunning ? "Listening\u{2026} speak through your glasses." : "No speech yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryText(scheme))
            } else {
                Text(speech.transcript)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.primaryText(scheme))
                    .textSelection(.enabled)
            }
        }
    }
}

extension AskSeed: Identifiable {
    var id: String { (verse?.id ?? "") + (initialText ?? "") }
}
