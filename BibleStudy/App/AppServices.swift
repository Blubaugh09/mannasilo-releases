import Foundation

/// Service factories built on demand from the current API keys in Settings.
/// Building fresh value types each call means changing a key in Settings takes
/// effect immediately on the next request — no stale clients to invalidate.
extension SettingsStore {
    func makeESV() -> ESVService {
        ESVService(apiKey: esvAPIKey)
    }

    func makeClaude() -> ClaudeService {
        ClaudeService(apiKey: claudeAPIKey, model: claudeModel.rawValue)
    }

    func makeDictionary() -> DictionaryService {
        DictionaryService()
    }

    func makeCrossReferences() -> CrossReferenceService {
        CrossReferenceService(claude: makeClaude(), esv: makeESV())
    }
}
