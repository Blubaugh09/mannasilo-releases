import SwiftUI
import SwiftData

/// The reading surface: fetches a chapter from the ESV API and renders it with
/// tap-to-define words, per-verse highlights, notes, and cross references.
struct ReaderView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore

    @StateObject private var viewModel = ReaderViewModel()

    @Query(sort: \ReadingPosition.updatedAt, order: .reverse) private var positions: [ReadingPosition]
    @Query private var highlights: [VerseHighlight]

    @State private var showPicker = false
    @State private var definitionWord: IdentifiableString?
    @State private var crossRefVerse: Verse?
    @State private var noteVerse: Verse?
    @State private var askVerse: Verse?
    @State private var actionVerse: Verse?
    @State private var didRestore = false

    private var typography: ReadingTypography {
        ReadingTypography(pointSize: settings.readingPointSize)
    }

    var body: some View {
        NavigationStack {
            Group {
                if !settings.hasESVKey {
                    missingKeyState
                } else if viewModel.isLoading && viewModel.passage == nil {
                    ProgressView("Loading\u{2026}")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let message = viewModel.errorMessage, viewModel.passage == nil {
                    VStack(spacing: Theme.Space.m) {
                        ErrorBanner(message: message, onDismiss: nil)
                        SecondaryButton(title: "Try again", systemImage: "arrow.clockwise") {
                            Task { await viewModel.load(using: settings.makeESV()) }
                        }
                    }
                    .padding()
                } else if let passage = viewModel.passage {
                    passageScroll(passage)
                } else {
                    EmptyStateView(systemImage: "book", title: "Ready to read",
                                   message: "Choose a passage to begin.")
                }
            }
            .navigationTitle(viewModel.reference.display)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .background(Theme.background(scheme))
            .sheet(isPresented: $showPicker) {
                PassagePickerView(current: viewModel.reference) { chosen in
                    showPicker = false
                    Task {
                        await viewModel.load(chosen, using: settings.makeESV())
                        savePosition()
                    }
                }
            }
            .sheet(item: $definitionWord) { item in
                WordDefinitionSheet(word: item.value)
            }
            .sheet(item: $crossRefVerse) { verse in
                CrossReferenceSheet(verse: verse)
            }
            .sheet(item: $noteVerse) { verse in
                NoteEditorView(reference: verse.reference, verse: verse.number)
            }
            .sheet(item: $askVerse) { verse in
                NavigationStack {
                    AskConversationView(seed: AskSeed(verse: verse))
                        .navigationTitle("Ask about \(verse.displayReference)")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(item: $actionVerse) { verse in
                VerseActionSheet(
                    verse: verse,
                    currentHighlight: highlight(for: verse.number),
                    onHighlight: { color in setHighlight(color, for: verse); actionVerse = nil },
                    onClearHighlight: { setHighlight(nil, for: verse); actionVerse = nil },
                    onNote: { actionVerse = nil; noteVerse = verse },
                    onCrossReferences: { actionVerse = nil; crossRefVerse = verse },
                    onAsk: { actionVerse = nil; askVerse = verse }
                )
                .presentationDetents([.medium])
            }
            .task {
                guard !didRestore else { return }
                didRestore = true
                if let saved = positions.first {
                    viewModel.reference = saved.reference
                }
                if settings.hasESVKey {
                    await viewModel.load(using: settings.makeESV())
                }
            }
        }
    }

    // MARK: Passage scroll

    private func passageScroll(_ passage: Passage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                ForEach(passage.verses) { verse in
                    VerseBlockView(
                        verse: verse,
                        headings: passage.headings.filter { $0.beforeVerse == verse.number },
                        highlight: highlight(for: verse.number),
                        typography: typography,
                        onWordTap: { definitionWord = IdentifiableString($0) },
                        onVerseAction: { actionVerse = $0 }
                    )
                }

                chapterNav
                copyright(passage.copyright)
            }
            .padding(Theme.Space.m)
        }
    }

    private var chapterNav: some View {
        HStack {
            SecondaryButton(title: "Previous", systemImage: "chevron.left") {
                Task { await viewModel.goPrevious(using: settings.makeESV()); savePosition() }
            }
            SecondaryButton(title: "Next", systemImage: "chevron.right") {
                Task { await viewModel.goNext(using: settings.makeESV()); savePosition() }
            }
        }
        .padding(.top, Theme.Space.m)
    }

    private func copyright(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(Theme.secondaryText(scheme))
            .padding(.top, Theme.Space.s)
    }

    private var missingKeyState: some View {
        EmptyStateView(
            systemImage: "key",
            title: "Add your ESV API key",
            message: "Open Settings and paste your free ESV API key to start reading."
        )
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { showPicker = true } label: {
                HStack(spacing: 4) {
                    Text(viewModel.reference.display).fontWeight(.semibold)
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Text size") {
                    Button { adjustSize(+1) } label: { Label("Larger", systemImage: "textformat.size.larger") }
                    Button { adjustSize(-1) } label: { Label("Smaller", systemImage: "textformat.size.smaller") }
                }
                Button {
                    Task { await viewModel.load(using: settings.makeESV()) }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "textformat.size")
            }
        }
    }

    // MARK: Highlights

    private var highlightMap: [Int: Theme.Accent] {
        var map: [Int: Theme.Accent] = [:]
        for h in highlights where h.bookID == viewModel.reference.bookID && h.chapter == viewModel.reference.chapter {
            map[h.verse] = h.color
        }
        return map
    }

    private func highlight(for verseNumber: Int) -> Theme.Accent? {
        highlightMap[verseNumber]
    }

    private func setHighlight(_ color: Theme.Accent?, for verse: Verse) {
        // Remove any existing highlight for this verse first.
        let existing = highlights.filter {
            $0.bookID == verse.reference.bookID && $0.chapter == verse.reference.chapter && $0.verse == verse.number
        }
        for item in existing { modelContext.delete(item) }

        if let color {
            let highlight = VerseHighlight(
                bookID: verse.reference.bookID,
                chapter: verse.reference.chapter,
                verse: verse.number,
                color: color
            )
            modelContext.insert(highlight)
        }
        try? modelContext.save()
    }

    // MARK: Reading position / text size

    private func savePosition() {
        let topVerse = viewModel.passage?.verses.first?.number ?? 1
        if let existing = positions.first {
            existing.bookID = viewModel.reference.bookID
            existing.chapter = viewModel.reference.chapter
            existing.scrollVerse = topVerse
            existing.updatedAt = .now
        } else {
            let position = ReadingPosition(
                bookID: viewModel.reference.bookID,
                chapter: viewModel.reference.chapter,
                scrollVerse: topVerse
            )
            modelContext.insert(position)
        }
        try? modelContext.save()
    }

    private func adjustSize(_ delta: Double) {
        let new = min(max(settings.readingPointSize + delta, ReadingTypography.minSize), ReadingTypography.maxSize)
        settings.readingPointSize = new
    }
}

/// A wrapper so a plain `String` can drive `.sheet(item:)`.
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
    init(_ value: String) { self.value = value }
}
