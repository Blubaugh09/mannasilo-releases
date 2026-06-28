import Foundation

/// Looks up plain-English word definitions from the free dictionaryapi.dev
/// service (no API key required). Used when the reader taps a word.
struct DictionaryService {

    struct Definition: Identifiable, Hashable {
        let id = UUID()
        let partOfSpeech: String
        let meaning: String
        let example: String?
    }

    struct Entry {
        let word: String
        let phonetic: String?
        let definitions: [Definition]
    }

    enum DictionaryError: LocalizedError {
        case notFound(String)
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .notFound(let word): return "No dictionary entry found for \u{201C}\(word)\u{201D}."
            case .transport(let error): return error.localizedDescription
            }
        }
    }

    private let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func lookup(_ rawWord: String) async throws -> Entry {
        let word = Self.normalize(rawWord)
        guard !word.isEmpty,
              let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encoded)") else {
            throw DictionaryError.notFound(rawWord)
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw DictionaryError.notFound(word)
            }
            let decoded = try JSONDecoder().decode([RawEntry].self, from: data)
            guard let first = decoded.first else { throw DictionaryError.notFound(word) }

            var definitions: [Definition] = []
            for meaning in first.meanings ?? [] {
                for def in meaning.definitions ?? [] {
                    definitions.append(Definition(
                        partOfSpeech: meaning.partOfSpeech ?? "",
                        meaning: def.definition,
                        example: def.example
                    ))
                }
            }
            let phonetic = first.phonetic ?? first.phonetics?.compactMap { $0.text }.first
            return Entry(word: first.word, phonetic: phonetic, definitions: Array(definitions.prefix(6)))
        } catch let error as DictionaryError {
            throw error
        } catch {
            throw DictionaryError.transport(error)
        }
    }

    /// Strip punctuation and lowercase so "beginning." → "beginning".
    static func normalize(_ word: String) -> String {
        word
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'-")).inverted)
            .joined()
            .lowercased()
    }

    // MARK: JSON shapes for dictionaryapi.dev
    private struct RawEntry: Decodable {
        let word: String
        let phonetic: String?
        let phonetics: [RawPhonetic]?
        let meanings: [RawMeaning]?
    }
    private struct RawPhonetic: Decodable { let text: String? }
    private struct RawMeaning: Decodable {
        let partOfSpeech: String?
        let definitions: [RawDefinition]?
    }
    private struct RawDefinition: Decodable {
        let definition: String
        let example: String?
    }
}
