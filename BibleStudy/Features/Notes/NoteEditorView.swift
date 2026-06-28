import SwiftUI
import SwiftData

/// Create or edit a study note. Anchored to a verse (from the reader) or to a
/// chapter, and freely editable later from the Notes tab.
struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    private let existingNote: StudyNote?
    private let bookID: Int
    private let chapter: Int
    private let verse: Int

    @State private var title: String
    @State private var bodyText: String

    /// Create a new note anchored to a reference.
    init(reference: ChapterReference, verse: Int) {
        self.existingNote = nil
        self.bookID = reference.bookID
        self.chapter = reference.chapter
        self.verse = verse
        _title = State(initialValue: "")
        _bodyText = State(initialValue: "")
    }

    /// Edit an existing note.
    init(note: StudyNote) {
        self.existingNote = note
        self.bookID = note.bookID
        self.chapter = note.chapter
        self.verse = note.verse
        _title = State(initialValue: note.title)
        _bodyText = State(initialValue: note.body)
    }

    private var anchorLabel: String {
        let book = BibleCanon.book(id: bookID).name
        return verse > 0 ? "\(book) \(chapter):\(verse)" : "\(book) \(chapter)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Pill(text: anchorLabel)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Section("Title") {
                    TextField("Optional title", text: $title)
                }
                Section("Note") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 220)
                }
            }
            .navigationTitle(existingNote == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        if let note = existingNote {
            note.title = title
            note.body = bodyText
            note.updatedAt = .now
        } else {
            let note = StudyNote(title: title, body: bodyText, bookID: bookID, chapter: chapter, verse: verse)
            modelContext.insert(note)
        }
        try? modelContext.save()
        dismiss()
    }
}
