import Foundation
import SwiftUI
import Combine

/// App-wide settings. Non-secret preferences live in UserDefaults and are
/// observable so the UI updates live; API keys are stored in the Keychain and
/// exposed through dedicated accessors. Settings are mutated from the UI (main
/// thread) but the service factories below can be read from background tasks.
final class SettingsStore: ObservableObject {

    // MARK: Reading preferences
    @Published var readingPointSize: Double {
        didSet { UserDefaults.standard.set(readingPointSize, forKey: "readingPointSize") }
    }

    @Published var accent: Theme.Accent {
        didSet {
            UserDefaults.standard.set(accent.rawValue, forKey: "accentColor")
        }
    }

    @Published var claudeModel: ClaudeModel {
        didSet {
            UserDefaults.standard.set(claudeModel.rawValue, forKey: "claudeModel")
        }
    }

    /// Whether tapping a word should also offer a "biblical sense" lookup via Claude.
    @Published var enableAIDefinitions: Bool {
        didSet { UserDefaults.standard.set(enableAIDefinitions, forKey: "enableAIDefinitions") }
    }

    // MARK: Secret keys (Keychain-backed, mirrored to @Published for the UI)
    @Published var esvAPIKey: String {
        didSet { KeychainStore.set(esvAPIKey, for: .esvAPIKey) }
    }

    @Published var claudeAPIKey: String {
        didSet { KeychainStore.set(claudeAPIKey, for: .claudeAPIKey) }
    }

    var hasESVKey: Bool { !esvAPIKey.trimmingCharacters(in: .whitespaces).isEmpty }
    var hasClaudeKey: Bool { !claudeAPIKey.trimmingCharacters(in: .whitespaces).isEmpty }

    init() {
        let defaults = UserDefaults.standard
        let storedSize = defaults.object(forKey: "readingPointSize") as? Double
        self.readingPointSize = storedSize ?? 20
        self.accent = Theme.Accent(rawValue: defaults.string(forKey: "accentColor") ?? "") ?? .indigo
        self.claudeModel = ClaudeModel(rawValue: defaults.string(forKey: "claudeModel") ?? "") ?? .opus48
        self.enableAIDefinitions = defaults.object(forKey: "enableAIDefinitions") as? Bool ?? true
        self.esvAPIKey = KeychainStore.get(.esvAPIKey) ?? ""
        self.claudeAPIKey = KeychainStore.get(.claudeAPIKey) ?? ""
    }
}

/// The Claude models the app offers. Opus 4.8 is the default — the most capable
/// tier for nuanced questions about scripture; Sonnet and Haiku are offered for
/// faster, lower-cost answers.
enum ClaudeModel: String, CaseIterable, Identifiable {
    case opus48 = "claude-opus-4-8"
    case sonnet46 = "claude-sonnet-4-6"
    case haiku45 = "claude-haiku-4-5"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .opus48:   return "Claude Opus 4.8"
        case .sonnet46: return "Claude Sonnet 4.6"
        case .haiku45:  return "Claude Haiku 4.5"
        }
    }

    var subtitle: String {
        switch self {
        case .opus48:   return "Most capable — best for deep study"
        case .sonnet46: return "Balanced speed and depth"
        case .haiku45:  return "Fastest, most economical"
        }
    }
}
