import Foundation

/// Talks to the official ESV API (https://api.esv.org). The user supplies their
/// own ESV API token in Settings. We use the plain-text passage endpoint and
/// parse it into structured verses so we can render each verse individually
/// (needed for tap-to-define, highlights, and per-verse notes).
struct ESVService {

    enum ESVError: LocalizedError {
        case missingKey
        case badResponse(Int)
        case emptyPassage
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "Add your ESV API key in Settings to read scripture."
            case .badResponse(let code):
                return "The ESV API returned an error (HTTP \(code)). Check that your API key is valid."
            case .emptyPassage:
                return "No text was returned for that passage."
            case .transport(let error):
                return error.localizedDescription
            }
        }
    }

    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Fetch and parse a chapter into structured verses + headings.
    func fetchChapter(_ reference: ChapterReference) async throws -> Passage {
        let raw = try await fetchRawText(query: reference.query)
        return Self.parse(raw, reference: reference)
    }

    /// Fetch the raw ESV plain text for an arbitrary query (used by cross references too).
    func fetchRawText(query: String) async throws -> ESVTextResponse {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ESVError.missingKey
        }

        var components = URLComponents(string: "https://api.esv.org/v3/passage/text/")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "include-passage-references", value: "false"),
            URLQueryItem(name: "include-verse-numbers", value: "true"),
            URLQueryItem(name: "include-first-verse-numbers", value: "true"),
            URLQueryItem(name: "include-footnotes", value: "false"),
            URLQueryItem(name: "include-headings", value: "true"),
            URLQueryItem(name: "include-short-copyright", value: "true"),
            URLQueryItem(name: "include-passage-horizontal-lines", value: "false"),
            URLQueryItem(name: "include-heading-horizontal-lines", value: "false"),
            URLQueryItem(name: "indent-paragraphs", value: "0"),
            URLQueryItem(name: "line-length", value: "0")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ESVError.badResponse(0) }
            guard (200...299).contains(http.statusCode) else {
                throw ESVError.badResponse(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(ESVTextResponse.self, from: data)
            guard !(decoded.passages?.isEmpty ?? true) else { throw ESVError.emptyPassage }
            return decoded
        } catch let error as ESVError {
            throw error
        } catch {
            throw ESVError.transport(error)
        }
    }

    // MARK: Parsing

    /// Parse the ESV plain-text blob into verses + section headings.
    static func parse(_ response: ESVTextResponse, reference: ChapterReference) -> Passage {
        let body = (response.passages ?? []).joined(separator: "\n")
        var copyright = "Scripture quotations are from the ESV® Bible, copyright © Crossway."

        // Strip the short copyright (the trailing " (ESV)" or full notice line).
        var working = body
        if let range = working.range(of: "(ESV)", options: .backwards) {
            copyright = String(working[range.lowerBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            working.removeSubrange(range.lowerBound..<working.endIndex)
        }

        var verses: [Verse] = []
        var headings: [PassageHeading] = []
        var pendingHeadings: [String] = []

        var currentNumber: Int? = nil
        var currentText = ""

        func flush() {
            if let number = currentNumber {
                let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    verses.append(Verse(reference: reference, number: number, text: text))
                }
            }
        }

        let lines = working.components(separatedBy: "\n")
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            let tokens = tokenize(line)
            if tokens.allSatisfy({ $0.number == nil }) {
                // A line with no verse markers is a section heading.
                pendingHeadings.append(line)
                continue
            }

            for token in tokens {
                if let number = token.number {
                    flush()
                    currentNumber = number
                    currentText = token.text
                    for heading in pendingHeadings {
                        headings.append(PassageHeading(beforeVerse: number, text: heading))
                    }
                    pendingHeadings.removeAll()
                } else if !token.text.isEmpty {
                    // Continuation text (a paragraph that continues a verse).
                    currentText += " " + token.text
                }
            }
        }
        flush()

        return Passage(reference: reference, verses: verses, headings: headings, copyright: copyright)
    }

    /// A chunk of a line: either text following a `[n]` marker, or leading text
    /// with no marker (number == nil).
    private struct Token { let number: Int?; let text: String }

    private static let markerRegex = try! NSRegularExpression(pattern: "\\[(\\d+)\\]")

    private static func tokenize(_ line: String) -> [Token] {
        let ns = line as NSString
        let matches = markerRegex.matches(in: line, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [Token(number: nil, text: line)] }

        var tokens: [Token] = []
        // Leading text before the first marker (continuation of previous verse).
        let firstStart = matches[0].range.location
        if firstStart > 0 {
            let lead = ns.substring(to: firstStart).trimmingCharacters(in: .whitespaces)
            if !lead.isEmpty { tokens.append(Token(number: nil, text: lead)) }
        }

        for (index, match) in matches.enumerated() {
            let number = Int(ns.substring(with: match.range(at: 1)))
            let textStart = match.range.location + match.range.length
            let textEnd = (index + 1 < matches.count) ? matches[index + 1].range.location : ns.length
            let text = ns.substring(with: NSRange(location: textStart, length: textEnd - textStart))
                .trimmingCharacters(in: .whitespaces)
            tokens.append(Token(number: number, text: text))
        }
        return tokens
    }
}

/// Matches the JSON shape returned by `/v3/passage/text/`.
struct ESVTextResponse: Decodable {
    let passages: [String]?
    let query: String?
}
