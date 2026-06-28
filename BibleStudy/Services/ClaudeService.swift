import Foundation

/// Talks directly to the Anthropic Messages API (https://api.anthropic.com).
/// The user supplies their own Claude API key in Settings.
///
/// Two entry points:
///  - `streamReply(...)`  — streams a chat answer token-by-token for the Ask tab.
///  - `complete(...)`     — a one-shot non-streaming call used for short
///                          structured tasks like generating cross references.
struct ClaudeService {

    enum ClaudeError: LocalizedError {
        case missingKey
        case badResponse(Int, String?)
        case decoding
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "Add your Claude API key in Settings to ask questions."
            case .badResponse(let code, let message):
                if let message { return "Claude API error (HTTP \(code)): \(message)" }
                return "Claude API error (HTTP \(code))."
            case .decoding:
                return "Could not read Claude's response."
            case .transport(let error):
                return error.localizedDescription
            }
        }
    }

    struct ChatMessage {
        enum Role: String { case user, assistant }
        let role: Role
        let content: String
    }

    private let apiKey: String
    private let model: String
    private let session: URLSession

    init(apiKey: String, model: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    // MARK: Streaming chat

    /// Stream a reply as an async sequence of text deltas. The caller appends
    /// each chunk to the visible answer for a live, typed-out feel.
    func streamReply(system: String,
                     history: [ChatMessage],
                     maxTokens: Int = 2048) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
                        throw ClaudeError.missingKey
                    }
                    let request = try makeRequest(system: system,
                                                  history: history,
                                                  maxTokens: maxTokens,
                                                  stream: true)
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw ClaudeError.badResponse(0, nil)
                    }
                    guard (200...299).contains(http.statusCode) else {
                        // Drain a little of the body for a useful message.
                        var message = ""
                        for try await line in bytes.lines { message += line; if message.count > 400 { break } }
                        throw ClaudeError.badResponse(http.statusCode, message.isEmpty ? nil : message)
                    }

                    // Parse Server-Sent Events. We only care about
                    // content_block_delta events carrying text_delta.
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        guard !payload.isEmpty, payload != "[DONE]" else { continue }
                        guard let data = payload.data(using: .utf8) else { continue }
                        if let text = Self.extractTextDelta(from: data) {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    let mapped = (error as? ClaudeError) ?? .transport(error)
                    continuation.finish(throwing: mapped)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: One-shot completion

    /// Non-streaming call that returns the full assistant text. Used for
    /// generating cross references where we want the complete result at once.
    func complete(system: String,
                  history: [ChatMessage],
                  maxTokens: Int = 1024) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ClaudeError.missingKey
        }
        let request = try makeRequest(system: system,
                                      history: history,
                                      maxTokens: maxTokens,
                                      stream: false)
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ClaudeError.badResponse(0, nil) }
            guard (200...299).contains(http.statusCode) else {
                let message = String(data: data, encoding: .utf8)
                throw ClaudeError.badResponse(http.statusCode, message)
            }
            guard let text = Self.extractFullText(from: data) else { throw ClaudeError.decoding }
            return text
        } catch let error as ClaudeError {
            throw error
        } catch {
            throw ClaudeError.transport(error)
        }
    }

    // MARK: Request building

    private func makeRequest(system: String,
                             history: [ChatMessage],
                             maxTokens: Int,
                             stream: Bool) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "stream": stream,
            "messages": history.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: Response parsing

    /// Pull the text out of a streaming `content_block_delta` event.
    private static func extractTextDelta(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard (object["type"] as? String) == "content_block_delta" else { return nil }
        guard let delta = object["delta"] as? [String: Any] else { return nil }
        guard (delta["type"] as? String) == "text_delta" else { return nil }
        return delta["text"] as? String
    }

    /// Concatenate all text blocks from a non-streaming response body.
    private static func extractFullText(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = object["content"] as? [[String: Any]] else { return nil }
        let text = content
            .filter { ($0["type"] as? String) == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
        return text.isEmpty ? nil : text
    }
}
