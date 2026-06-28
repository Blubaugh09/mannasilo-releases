import Foundation

/// Generates cross references for a verse. Rather than bundling a static
/// dataset, we ask Claude (which the user has already configured) for the most
/// relevant cross references and a one-line reason for each, then fetch the
/// referenced text from the ESV API so the user sees the actual words.
struct CrossReferenceService {

    struct CrossReference: Identifiable, Hashable {
        let id = UUID()
        let reference: String   // e.g. "Genesis 1:1"
        let reason: String      // one-line connection
        var text: String?       // ESV text, filled in after fetching
    }

    private let claude: ClaudeService
    private let esv: ESVService

    init(claude: ClaudeService, esv: ESVService) {
        self.claude = claude
        self.esv = esv
    }

    /// Ask Claude for cross references, then hydrate each with ESV text.
    func crossReferences(for verse: Verse) async throws -> [CrossReference] {
        let system = """
        You are a careful biblical cross-reference assistant. Given a verse, list the most \
        relevant cross references from elsewhere in Scripture. Respond with ONLY a JSON array \
        (no prose, no markdown fences) of objects with exactly these keys: "reference" (a \
        standard Bible reference string like "John 3:16" or "Romans 5:8-9") and "reason" (a \
        concise one-sentence explanation of the connection). Return between 3 and 7 entries. \
        Use widely recognized canonical references only.
        """
        let prompt = "Verse: \(verse.displayReference)\n\(verse.text)"

        let raw = try await claude.complete(
            system: system,
            history: [.init(role: .user, content: prompt)],
            maxTokens: 1024
        )

        var references = Self.parse(raw)

        // Hydrate each reference with the ESV text. Failures are non-fatal —
        // we still show the reference and reason.
        await withTaskGroup(of: (Int, String?).self) { group in
            for (index, ref) in references.enumerated() {
                group.addTask {
                    let text = try? await esv.fetchRawText(query: ref.reference).passages?
                        .joined(separator: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return (index, text)
                }
            }
            for await (index, text) in group {
                if let text, !text.isEmpty {
                    references[index].text = Self.cleanVerseText(text)
                }
            }
        }

        return references
    }

    /// Extract the JSON array from Claude's reply, tolerating stray text.
    static func parse(_ raw: String) -> [CrossReference] {
        guard let start = raw.firstIndex(of: "["),
              let end = raw.lastIndex(of: "]") else { return [] }
        let jsonSlice = String(raw[start...end])
        guard let data = jsonSlice.data(using: .utf8),
              let array = try? JSONDecoder().decode([RawRef].self, from: data) else {
            return []
        }
        return array.map { CrossReference(reference: $0.reference, reason: $0.reason, text: nil) }
    }

    /// Strip verse-number markers and the copyright tag from fetched text.
    private static func cleanVerseText(_ text: String) -> String {
        var cleaned = text.replacingOccurrences(
            of: "\\[\\d+\\]",
            with: "",
            options: .regularExpression
        )
        if let range = cleaned.range(of: "(ESV)", options: .backwards) {
            cleaned.removeSubrange(range.lowerBound..<cleaned.endIndex)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct RawRef: Decodable {
        let reference: String
        let reason: String
    }
}
