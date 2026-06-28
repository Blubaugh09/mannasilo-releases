import SwiftUI
import UIKit

/// Renders a single verse: any section headings that precede it, the verse
/// number, and the verse words laid out as individually-tappable elements so a
/// tap on any word can trigger a definition lookup.
struct VerseBlockView: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: SettingsStore

    let verse: Verse
    let headings: [PassageHeading]
    let highlight: Theme.Accent?
    let typography: ReadingTypography

    let onWordTap: (String) -> Void
    let onVerseAction: (Verse) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            ForEach(headings) { heading in
                Text(heading.text)
                    .font(typography.headingFont)
                    .foregroundStyle(settings.accent.color)
                    .padding(.top, Theme.Space.s)
            }

            FlowLayout(spacing: 5, lineSpacing: typography.lineSpacing) {
                // Verse number — tap for the verse action menu.
                Button {
                    onVerseAction(verse)
                } label: {
                    Text("\(verse.number)")
                        .font(typography.verseNumberFont)
                        .foregroundStyle(settings.accent.color)
                        .baselineOffset(typography.pointSize * 0.25)
                }
                .buttonStyle(.plain)

                // Words — tap any word for a definition.
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Button {
                        onWordTap(word)
                    } label: {
                        Text(word)
                            .font(typography.verseFont)
                            .foregroundStyle(Theme.primaryText(scheme))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Space.s)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .fill(highlight?.color.opacity(scheme == .dark ? 0.28 : 0.18) ?? .clear)
            )
            .contextMenu {
                verseMenu
            }
        }
    }

    private var words: [String] {
        verse.text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
    }

    @ViewBuilder private var verseMenu: some View {
        Button {
            onVerseAction(verse)
        } label: {
            Label("Verse actions\u{2026}", systemImage: "ellipsis.circle")
        }
        Button {
            UIPasteboard.general.string = "\(verse.displayReference) \u{2014} \(verse.text)"
        } label: {
            Label("Copy verse", systemImage: "doc.on.doc")
        }
    }
}
