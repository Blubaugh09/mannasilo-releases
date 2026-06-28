import SwiftUI

/// The chat surface for asking Claude about scripture. Used both as the Ask tab
/// and as a sheet seeded from a specific verse.
struct AskConversationView: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: SettingsStore

    @StateObject private var viewModel: AskViewModel

    init(seed: AskSeed = AskSeed()) {
        _viewModel = StateObject(wrappedValue: AskViewModel(seed: seed))
    }

    var body: some View {
        VStack(spacing: 0) {
            if !settings.hasClaudeKey {
                EmptyStateView(
                    systemImage: "key",
                    title: "Add your Claude API key",
                    message: "Open Settings and paste your Claude API key to ask questions about the text."
                )
            } else {
                conversation
                inputBar
            }
        }
        .background(Theme.background(scheme))
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Space.m) {
                    if let verse = viewModel.seedVerse {
                        Card {
                            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                                Pill(text: verse.displayReference, tint: settings.accent.color)
                                Text(verse.text)
                                    .font(.custom("Georgia", size: 15))
                                    .foregroundStyle(Theme.primaryText(scheme))
                            }
                        }
                    }

                    if viewModel.messages.isEmpty {
                        suggestionsView
                    }

                    ForEach(viewModel.messages) { message in
                        bubble(message).id(message.id)
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                    }
                }
                .padding(Theme.Space.m)
            }
            .onChange(of: viewModel.messages.last?.text) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            SectionHeader(title: "Try asking", systemImage: "lightbulb")
            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                Button {
                    viewModel.send(suggestion, using: settings.makeClaude())
                } label: {
                    HStack {
                        Text(suggestion).foregroundStyle(Theme.primaryText(scheme))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(settings.accent.color)
                    }
                }
                .buttonStyle(.plain)
                .padding(Theme.Space.m)
                .background(Theme.secondaryBackground(scheme))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            }
        }
    }

    private func bubble(_ message: AskViewModel.Message) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading) {
                if message.role == .assistant && message.text.isEmpty {
                    ProgressView()
                } else {
                    Text(message.text)
                        .foregroundStyle(message.role == .user ? .white : Theme.primaryText(scheme))
                        .textSelection(.enabled)
                }
            }
            .padding(Theme.Space.m)
            .background(message.role == .user ? settings.accent.color : Theme.secondaryBackground(scheme))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: Theme.Space.s) {
            TextField("Ask about the text\u{2026}", text: $viewModel.input, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, Theme.Space.m)
                .padding(.vertical, 10)
                .background(Theme.secondaryBackground(scheme))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))

            if viewModel.isStreaming {
                Button { viewModel.stop() } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(settings.accent.color)
                }
            } else {
                Button { viewModel.send(using: settings.makeClaude()) } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? Theme.secondaryText(scheme) : settings.accent.color)
                }
                .disabled(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Theme.Space.m)
        .background(.ultraThinMaterial)
    }
}
