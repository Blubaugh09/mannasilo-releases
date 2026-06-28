import SwiftUI
import SwiftData

/// All study notes, newest first. Tap to edit, swipe to delete, and add a new
/// free note anchored to wherever you're currently reading.
struct NotesView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StudyNote.updatedAt, order: .reverse) private var notes: [StudyNote]
    @Query(sort: \ReadingPosition.updatedAt, order: .reverse) private var positions: [ReadingPosition]

    @State private var editingNote: StudyNote?
    @State private var creatingNote = false

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    EmptyStateView(
                        systemImage: "note.text",
                        title: "No notes yet",
                        message: "Tap a verse number while reading to add a note, or use the + button."
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            Button {
                                editingNote = note
                            } label: {
                                noteRow(note)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { creatingNote = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(item: $editingNote) { note in
                NoteEditorView(note: note)
            }
            .sheet(isPresented: $creatingNote) {
                let ref = positions.first?.reference ?? .defaultStart
                NoteEditorView(reference: ref, verse: 0)
            }
        }
    }

    private func noteRow(_ note: StudyNote) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack {
                Pill(text: note.anchorReference)
                Spacer()
                Text(note.updatedAt, style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
            }
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(notes[index]) }
        try? modelContext.save()
    }
}
