import Foundation
import SwiftData

// MARK: - Persisted models (SwiftData, iOS 17+)
//
// Notes, highlights, and the last-read position all live in SwiftData so they
// survive launches and sync to the user's own device storage. Nothing here
// leaves the phone unless the user explicitly asks Claude a question.

/// A study note. It can be attached to a specific verse, or be a free-floating
/// note about a chapter/topic.
@Model
final class StudyNote {
    var title: String
    var body: String
    /// Canonical book id + chapter + verse the note is anchored to (verse may be 0 for chapter-level).
    var bookID: Int
    var chapter: Int
    var verse: Int
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "",
         body: String = "",
         bookID: Int,
         chapter: Int,
         verse: Int = 0,
         createdAt: Date = .now) {
        self.title = title
        self.body = body
        self.bookID = bookID
        self.chapter = chapter
        self.verse = verse
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    var anchorReference: String {
        let book = BibleCanon.book(id: bookID).name
        return verse > 0 ? "\(book) \(chapter):\(verse)" : "\(book) \(chapter)"
    }
}

/// A persisted verse highlight in one of the accent tints.
@Model
final class VerseHighlight {
    var bookID: Int
    var chapter: Int
    var verse: Int
    var colorRaw: String   // Theme.Accent.rawValue
    var createdAt: Date

    init(bookID: Int, chapter: Int, verse: Int, color: Theme.Accent, createdAt: Date = .now) {
        self.bookID = bookID
        self.chapter = chapter
        self.verse = verse
        self.colorRaw = color.rawValue
        self.createdAt = createdAt
    }

    var color: Theme.Accent { Theme.Accent(rawValue: colorRaw) ?? .amber }
}

/// The single "where I left off" bookmark plus a small recents list.
@Model
final class ReadingPosition {
    var bookID: Int
    var chapter: Int
    var scrollVerse: Int    // the topmost visible verse, for restoring scroll
    var updatedAt: Date

    init(bookID: Int, chapter: Int, scrollVerse: Int = 1, updatedAt: Date = .now) {
        self.bookID = bookID
        self.chapter = chapter
        self.scrollVerse = scrollVerse
        self.updatedAt = updatedAt
    }

    var reference: ChapterReference {
        ChapterReference(bookID: bookID, chapter: chapter)
    }
}
