import Foundation
import Combine

/// Loads chapters from the ESV API and tracks the current reading reference.
@MainActor
final class ReaderViewModel: ObservableObject {
    @Published var reference: ChapterReference
    @Published private(set) var passage: Passage?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init(reference: ChapterReference = .defaultStart) {
        self.reference = reference
    }

    /// Load the current `reference` using the supplied ESV client.
    func load(using esv: ESVService) async {
        await load(reference, using: esv)
    }

    func load(_ ref: ChapterReference, using esv: ESVService) async {
        isLoading = true
        errorMessage = nil
        reference = ref
        do {
            let result = try await esv.fetchChapter(ref)
            // Guard against a stale response if the user moved on quickly.
            if reference == ref {
                passage = result
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            passage = nil
        }
        isLoading = false
    }

    func goNext(using esv: ESVService) async {
        guard let next = BibleCanon.next(after: reference) else { return }
        await load(next, using: esv)
    }

    func goPrevious(using esv: ESVService) async {
        guard let previous = BibleCanon.previous(before: reference) else { return }
        await load(previous, using: esv)
    }
}
