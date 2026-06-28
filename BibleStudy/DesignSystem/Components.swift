import SwiftUI

// MARK: - Reusable building blocks
//
// Small, composable views shared across screens so the visual language stays
// consistent: cards, buttons, section headers, empty states, pills.

/// A soft surface card with hairline border. Used for grouping content.
struct Card<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = Theme.Space.m
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.secondaryBackground(scheme))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .stroke(Theme.hairline(scheme), lineWidth: 1)
            )
    }
}

/// Primary filled action button, tinted with the accent color.
struct PrimaryButton: View {
    @EnvironmentObject private var settings: SettingsStore
    var title: String
    var systemImage: String?
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(settings.accent.color)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.85 : 1)
    }
}

/// Quiet, bordered secondary button.
struct SecondaryButton: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: SettingsStore
    var title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(settings.accent.color)
            .background(settings.accent.color.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// A small rounded pill, e.g. for a verse reference or a status chip.
struct Pill: View {
    @Environment(\.colorScheme) private var scheme
    var text: String
    var tint: Color?

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(tint ?? Theme.secondaryText(scheme))
            .background((tint ?? Theme.secondaryText(scheme)).opacity(0.12))
            .clipShape(Capsule())
    }
}

/// Section header used inside scroll views.
struct SectionHeader: View {
    @Environment(\.colorScheme) private var scheme
    var title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(0.6)
            Spacer()
        }
        .foregroundStyle(Theme.secondaryText(scheme))
    }
}

/// Friendly empty state with an icon, title, and subtitle.
struct EmptyStateView: View {
    @Environment(\.colorScheme) private var scheme
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.secondaryText(scheme))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.primaryText(scheme))
            Text(message)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Space.xl)
    }
}

/// Inline banner for surfacing an error in context.
struct ErrorBanner: View {
    var message: String
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.s) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(Color(red: 0.92, green: 0.30, blue: 0.45))
        .padding(Theme.Space.m)
        .background(Color(red: 0.92, green: 0.30, blue: 0.45).opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
    }
}
