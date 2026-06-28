import SwiftUI

/// API keys, appearance, reading preferences, and credits. Keys are stored in
/// the device Keychain — they never leave the phone except in requests you make.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: SettingsStore

    @State private var revealESV = false
    @State private var revealClaude = false

    var body: some View {
        NavigationStack {
            Form {
                apiKeysSection
                aiSection
                appearanceSection
                readingSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: API keys

    private var apiKeysSection: some View {
        Section {
            keyField(
                title: "ESV API key",
                systemImage: "book",
                text: $settings.esvAPIKey,
                reveal: $revealESV,
                isSet: settings.hasESVKey
            )
            Link(destination: URL(string: "https://api.esv.org/")!) {
                Label("Get a free ESV API key", systemImage: "arrow.up.right.square")
                    .font(.system(size: 13))
            }

            keyField(
                title: "Claude API key",
                systemImage: "sparkles",
                text: $settings.claudeAPIKey,
                reveal: $revealClaude,
                isSet: settings.hasClaudeKey
            )
            Link(destination: URL(string: "https://console.anthropic.com/")!) {
                Label("Get a Claude API key", systemImage: "arrow.up.right.square")
                    .font(.system(size: 13))
            }
        } header: {
            Text("API Keys")
        } footer: {
            Text("Keys are stored securely in your device Keychain and are only sent to the ESV and Anthropic APIs when you read or ask a question.")
        }
    }

    private func keyField(title: String,
                          systemImage: String,
                          text: Binding<String>,
                          reveal: Binding<Bool>,
                          isSet: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                if isSet {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(settings.accent.color)
                        .font(.system(size: 13))
                }
            }
            HStack {
                if reveal.wrappedValue {
                    TextField("Paste your key", text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("Paste your key", text: text)
                }
                Button { reveal.wrappedValue.toggle() } label: {
                    Image(systemName: reveal.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
                .buttonStyle(.plain)
            }
            .font(.system(.body, design: .monospaced))
        }
    }

    // MARK: AI

    private var aiSection: some View {
        Section("Claude") {
            Picker("Model", selection: $settings.claudeModel) {
                ForEach(ClaudeModel.allCases) { model in
                    VStack(alignment: .leading) {
                        Text(model.displayName)
                    }.tag(model)
                }
            }
            Text(settings.claudeModel.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText(scheme))

            Toggle("AI word meanings", isOn: $settings.enableAIDefinitions)
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Accent color")
                HStack(spacing: Theme.Space.m) {
                    ForEach(Theme.Accent.allCases) { accent in
                        Button { settings.accent = accent } label: {
                            Circle()
                                .fill(accent.color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Theme.primaryText(scheme),
                                                    lineWidth: settings.accent == accent ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Reading

    private var readingSection: some View {
        Section("Reading") {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                HStack {
                    Text("Text size")
                    Spacer()
                    Text("\(Int(settings.readingPointSize)) pt")
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
                Slider(value: $settings.readingPointSize,
                       in: ReadingTypography.minSize...ReadingTypography.maxSize,
                       step: 1)
                Text("In the beginning, God created the heavens and the earth.")
                    .font(.custom("Georgia", size: settings.readingPointSize))
                    .foregroundStyle(Theme.primaryText(scheme))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            Text("Manna Silo \u{2014} a quiet place to read, study, and listen to the Word.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText(scheme))
            Text("Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), © Crossway. Used by permission. All rights reserved.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondaryText(scheme))
        }
    }
}
