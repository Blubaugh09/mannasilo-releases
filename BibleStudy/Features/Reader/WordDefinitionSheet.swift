import SwiftUI

/// Shown when the reader taps a word. Looks the word up in a free English
/// dictionary, and optionally offers a contextual/biblical sense via Claude.
struct WordDefinitionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: SettingsStore

    let word: String

    @State private var entry: DictionaryService.Entry?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var aiSense: String = ""
    @State private var isAskingAI = false

    private var cleanWord: String { DictionaryService.normalize(word) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    header

                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    } else if let entry, !entry.definitions.isEmpty {
                        definitionsView(entry)
                    } else if let errorMessage {
                        ErrorBanner(message: errorMessage, onDismiss: nil)
                    }

                    if settings.enableAIDefinitions {
                        aiSection
                    }
                }
                .padding(Theme.Space.l)
            }
            .navigationTitle("Definition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .task { await load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(entry?.word ?? cleanWord)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Theme.primaryText(scheme))
            if let phonetic = entry?.phonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
        }
    }

    private func definitionsView(_ entry: DictionaryService.Entry) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            ForEach(Array(entry.definitions.enumerated()), id: \.offset) { index, def in
                Card {
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        if !def.partOfSpeech.isEmpty {
                            Pill(text: def.partOfSpeech, tint: settings.accent.color)
                        }
                        Text(def.meaning)
                            .foregroundStyle(Theme.primaryText(scheme))
                        if let example = def.example {
                            Text("\u{201C}\(example)\u{201D}")
                                .font(.system(size: 14))
                                .italic()
                                .foregroundStyle(Theme.secondaryText(scheme))
                        }
                    }
                }
            }
        }
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            SectionHeader(title: "Meaning in scripture", systemImage: "sparkles")
            if !aiSense.isEmpty {
                Card { Text(aiSense).foregroundStyle(Theme.primaryText(scheme)) }
            } else {
                SecondaryButton(
                    title: isAskingAI ? "Thinking\u{2026}" : "Explain the biblical sense",
                    systemImage: "sparkles"
                ) {
                    Task { await askAI() }
                }
                .disabled(isAskingAI || !settings.hasClaudeKey)
                if !settings.hasClaudeKey {
                    Text("Add your Claude API key in Settings to enable this.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entry = try await settings.makeDictionary().lookup(word)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func askAI() async {
        guard settings.hasClaudeKey else { return }
        isAskingAI = true
        defer { isAskingAI = false }
        let system = """
        You are a concise biblical study assistant. Explain the meaning of a single word as it is \
        commonly used in the Bible, including its original-language sense (Hebrew or Greek) when \
        relevant. Keep it to 2\u{2013}4 sentences, plain and accessible.
        """
        do {
            aiSense = try await settings.makeClaude().complete(
                system: system,
                history: [.init(role: .user, content: "Word: \(cleanWord)")],
                maxTokens: 400
            )
        } catch {
            aiSense = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
