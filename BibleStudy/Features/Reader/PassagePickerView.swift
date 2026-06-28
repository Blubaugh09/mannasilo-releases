import SwiftUI

/// Two-step navigator: pick a book, then a chapter. Books are grouped by
/// testament and searchable.
struct PassagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: SettingsStore

    let current: ChapterReference
    let onSelect: (ChapterReference) -> Void

    @State private var search = ""
    @State private var selectedBook: BibleBook?

    var body: some View {
        NavigationStack {
            Group {
                if let book = selectedBook {
                    chapterGrid(book)
                } else {
                    bookList
                }
            }
            .navigationTitle(selectedBook?.name ?? "Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedBook != nil {
                        Button("Books") { selectedBook = nil }
                    } else {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
    }

    private var bookList: some View {
        List {
            ForEach([BibleBook.Testament.old, .new], id: \.self) { testament in
                Section(testament.rawValue) {
                    ForEach(filteredBooks.filter { $0.testament == testament }) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            HStack {
                                Text(book.name)
                                    .foregroundStyle(Theme.primaryText(scheme))
                                Spacer()
                                Text("\(book.chapters)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.secondaryText(scheme))
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Find a book")
    }

    private func chapterGrid(_ book: BibleBook) -> some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.s), count: 5),
                      spacing: Theme.Space.s) {
                ForEach(1...book.chapters, id: \.self) { chapter in
                    let isCurrent = (book.id == current.bookID && chapter == current.chapter)
                    Button {
                        onSelect(ChapterReference(bookID: book.id, chapter: chapter))
                    } label: {
                        Text("\(chapter)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(isCurrent ? .white : Theme.primaryText(scheme))
                            .background(isCurrent ? settings.accent.color : Theme.secondaryBackground(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Space.m)
        }
    }

    private var filteredBooks: [BibleBook] {
        let trimmed = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return BibleCanon.books }
        return BibleCanon.books.filter {
            $0.name.lowercased().contains(trimmed) || $0.abbreviation.lowercased().contains(trimmed)
        }
    }
}
