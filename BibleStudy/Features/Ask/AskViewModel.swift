import Foundation
import Combine

/// Optional context that seeds an Ask conversation (e.g. when launched from a
/// verse's "Ask Claude about this" action).
struct AskSeed {
    let verse: Verse?
    let initialText: String?
    init(verse: Verse? = nil, initialText: String? = nil) {
        self.verse = verse
        self.initialText = initialText
    }
}

/// Drives a streaming conversation with Claude about scripture.
@MainActor
final class AskViewModel: ObservableObject {

    struct Message: Identifiable {
        enum Role { case user, assistant }
        let id = UUID()
        let role: Role
        var text: String
    }

    @Published var messages: [Message] = []
    @Published var input: String = ""
    @Published private(set) var isStreaming = false
    @Published var errorMessage: String?

    let seedVerse: Verse?
    private var streamTask: Task<Void, Never>?

    init(seed: AskSeed = AskSeed()) {
        self.seedVerse = seed.verse
        if let initialText = seed.initialText {
            self.input = initialText
        }
    }

    /// Suggested opening questions shown before the first message.
    var suggestions: [String] {
        if seedVerse != nil {
            return ["What does this verse mean?",
                    "What is the historical context?",
                    "How does this apply to my life?"]
        }
        return ["Explain the theme of Psalm 23",
                "What is the gospel in one paragraph?",
                "Compare the four Gospels"]
    }

    private var systemPrompt: String {
        var prompt = """
        You are a knowledgeable, gracious Bible study companion. Answer questions about the \
        biblical text accurately and accessibly. Cite book, chapter, and verse where it helps. \
        Distinguish clearly between the plain meaning of the text, widely held interpretations, \
        and your own suggestions. If a question is outside scripture or you are unsure, say so \
        honestly. Keep answers focused and well-structured.
        """
        if let verse = seedVerse {
            prompt += "\n\nThe user is currently studying \(verse.displayReference): \"\(verse.text)\""
        }
        return prompt
    }

    func send(_ text: String? = nil, using claude: ClaudeService) {
        let content = (text ?? input).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isStreaming else { return }
        errorMessage = nil
        input = ""

        messages.append(Message(role: .user, text: content))
        let assistantIndex = messages.count
        messages.append(Message(role: .assistant, text: ""))
        isStreaming = true

        let history = messages
            .prefix(assistantIndex)   // exclude the empty assistant placeholder
            .map { ClaudeService.ChatMessage(role: $0.role == .user ? .user : .assistant, content: $0.text) }

        streamTask = Task {
            do {
                let stream = claude.streamReply(system: systemPrompt, history: Array(history))
                for try await delta in stream {
                    if assistantIndex < messages.count {
                        messages[assistantIndex].text += delta
                    }
                }
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                // Drop the empty assistant bubble if nothing streamed.
                if assistantIndex < messages.count, messages[assistantIndex].text.isEmpty {
                    messages.remove(at: assistantIndex)
                }
            }
            isStreaming = false
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    func reset() {
        stop()
        messages.removeAll()
        errorMessage = nil
    }
}
