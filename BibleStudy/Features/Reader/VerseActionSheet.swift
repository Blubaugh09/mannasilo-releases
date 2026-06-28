import SwiftUI

/// The menu shown when the reader taps a verse number: highlight in a color,
/// add a note, see cross references, or ask Claude about it.
struct VerseActionSheet: View {
    @Environment(\.colorScheme) private var scheme

    let verse: Verse
    let currentHighlight: Theme.Accent?
    let onHighlight: (Theme.Accent) -> Void
    let onClearHighlight: () -> Void
    let onNote: () -> Void
    let onCrossReferences: () -> Void
    let onAsk: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Pill(text: verse.displayReference)
                Text(verse.text)
                    .font(.custom("Georgia", size: 16))
                    .foregroundStyle(Theme.primaryText(scheme))
                    .lineLimit(3)
            }

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                SectionHeader(title: "Highlight", systemImage: "highlighter")
                HStack(spacing: Theme.Space.m) {
                    ForEach(Theme.Accent.allCases) { color in
                        Button { onHighlight(color) } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Theme.primaryText(scheme),
                                                    lineWidth: currentHighlight == color ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    if currentHighlight != nil {
                        Button(action: onClearHighlight) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.secondaryText(scheme))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(spacing: Theme.Space.s) {
                actionRow("Add note", systemImage: "square.and.pencil", action: onNote)
                actionRow("Cross references", systemImage: "arrow.triangle.branch", action: onCrossReferences)
                actionRow("Ask Claude about this", systemImage: "sparkles", action: onAsk)
            }

            Spacer()
        }
        .padding(Theme.Space.l)
    }

    private func actionRow(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage).frame(width: 26)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            .padding(.vertical, 6)
            .foregroundStyle(Theme.primaryText(scheme))
        }
        .buttonStyle(.plain)
    }
}
