import Foundation

/// A book of the Bible with its canonical chapter count. Chapter counts are
/// fixed across translations, so we can drive the navigation UI entirely
/// offline and only hit the ESV API to fetch the actual text.
struct BibleBook: Identifiable, Hashable {
    let id: Int            // 1-based canonical order (Genesis = 1)
    let name: String       // "Genesis"
    let abbreviation: String
    let chapters: Int
    let testament: Testament

    enum Testament: String { case old = "Old Testament", new = "New Testament" }
}

/// A pointer to a specific chapter the reader is viewing.
struct ChapterReference: Equatable, Codable, Hashable {
    var bookID: Int
    var chapter: Int

    var book: BibleBook { BibleCanon.book(id: bookID) }

    /// The query string the ESV API understands, e.g. "John 3".
    var query: String { "\(book.name) \(chapter)" }

    /// Human display, e.g. "John 3".
    var display: String { query }

    static let defaultStart = ChapterReference(bookID: 43, chapter: 1) // John 1
}

/// A single parsed verse from a passage.
struct Verse: Identifiable, Hashable {
    var id: String { "\(reference.bookID).\(reference.chapter).\(number)" }
    let reference: ChapterReference
    let number: Int
    let text: String

    /// "John 3:16"
    var displayReference: String { "\(reference.book.name) \(reference.chapter):\(number)" }
}

/// A heading line that may appear inside a passage (e.g. "The Birth of Jesus").
struct PassageHeading: Identifiable, Hashable {
    let id = UUID()
    let beforeVerse: Int     // heading is shown immediately before this verse number
    let text: String
}

/// The full result of fetching a chapter: verses plus any section headings.
struct Passage {
    let reference: ChapterReference
    let verses: [Verse]
    let headings: [PassageHeading]
    let copyright: String
}

/// The canonical 66-book list with chapter counts.
enum BibleCanon {
    static let books: [BibleBook] = [
        .init(id: 1,  name: "Genesis",         abbreviation: "Gen",  chapters: 50, testament: .old),
        .init(id: 2,  name: "Exodus",          abbreviation: "Exod", chapters: 40, testament: .old),
        .init(id: 3,  name: "Leviticus",       abbreviation: "Lev",  chapters: 27, testament: .old),
        .init(id: 4,  name: "Numbers",         abbreviation: "Num",  chapters: 36, testament: .old),
        .init(id: 5,  name: "Deuteronomy",     abbreviation: "Deut", chapters: 34, testament: .old),
        .init(id: 6,  name: "Joshua",          abbreviation: "Josh", chapters: 24, testament: .old),
        .init(id: 7,  name: "Judges",          abbreviation: "Judg", chapters: 21, testament: .old),
        .init(id: 8,  name: "Ruth",            abbreviation: "Ruth", chapters: 4,  testament: .old),
        .init(id: 9,  name: "1 Samuel",        abbreviation: "1Sam", chapters: 31, testament: .old),
        .init(id: 10, name: "2 Samuel",        abbreviation: "2Sam", chapters: 24, testament: .old),
        .init(id: 11, name: "1 Kings",         abbreviation: "1Kgs", chapters: 22, testament: .old),
        .init(id: 12, name: "2 Kings",         abbreviation: "2Kgs", chapters: 25, testament: .old),
        .init(id: 13, name: "1 Chronicles",    abbreviation: "1Chr", chapters: 29, testament: .old),
        .init(id: 14, name: "2 Chronicles",    abbreviation: "2Chr", chapters: 36, testament: .old),
        .init(id: 15, name: "Ezra",            abbreviation: "Ezra", chapters: 10, testament: .old),
        .init(id: 16, name: "Nehemiah",        abbreviation: "Neh",  chapters: 13, testament: .old),
        .init(id: 17, name: "Esther",          abbreviation: "Esth", chapters: 10, testament: .old),
        .init(id: 18, name: "Job",             abbreviation: "Job",  chapters: 42, testament: .old),
        .init(id: 19, name: "Psalms",          abbreviation: "Ps",   chapters: 150, testament: .old),
        .init(id: 20, name: "Proverbs",        abbreviation: "Prov", chapters: 31, testament: .old),
        .init(id: 21, name: "Ecclesiastes",    abbreviation: "Eccl", chapters: 12, testament: .old),
        .init(id: 22, name: "Song of Solomon", abbreviation: "Song", chapters: 8,  testament: .old),
        .init(id: 23, name: "Isaiah",          abbreviation: "Isa",  chapters: 66, testament: .old),
        .init(id: 24, name: "Jeremiah",        abbreviation: "Jer",  chapters: 52, testament: .old),
        .init(id: 25, name: "Lamentations",    abbreviation: "Lam",  chapters: 5,  testament: .old),
        .init(id: 26, name: "Ezekiel",         abbreviation: "Ezek", chapters: 48, testament: .old),
        .init(id: 27, name: "Daniel",          abbreviation: "Dan",  chapters: 12, testament: .old),
        .init(id: 28, name: "Hosea",           abbreviation: "Hos",  chapters: 14, testament: .old),
        .init(id: 29, name: "Joel",            abbreviation: "Joel", chapters: 3,  testament: .old),
        .init(id: 30, name: "Amos",            abbreviation: "Amos", chapters: 9,  testament: .old),
        .init(id: 31, name: "Obadiah",         abbreviation: "Obad", chapters: 1,  testament: .old),
        .init(id: 32, name: "Jonah",           abbreviation: "Jonah", chapters: 4, testament: .old),
        .init(id: 33, name: "Micah",           abbreviation: "Mic",  chapters: 7,  testament: .old),
        .init(id: 34, name: "Nahum",           abbreviation: "Nah",  chapters: 3,  testament: .old),
        .init(id: 35, name: "Habakkuk",        abbreviation: "Hab",  chapters: 3,  testament: .old),
        .init(id: 36, name: "Zephaniah",       abbreviation: "Zeph", chapters: 3,  testament: .old),
        .init(id: 37, name: "Haggai",          abbreviation: "Hag",  chapters: 2,  testament: .old),
        .init(id: 38, name: "Zechariah",       abbreviation: "Zech", chapters: 14, testament: .old),
        .init(id: 39, name: "Malachi",         abbreviation: "Mal",  chapters: 4,  testament: .old),
        .init(id: 40, name: "Matthew",         abbreviation: "Matt", chapters: 28, testament: .new),
        .init(id: 41, name: "Mark",            abbreviation: "Mark", chapters: 16, testament: .new),
        .init(id: 42, name: "Luke",            abbreviation: "Luke", chapters: 24, testament: .new),
        .init(id: 43, name: "John",            abbreviation: "John", chapters: 21, testament: .new),
        .init(id: 44, name: "Acts",            abbreviation: "Acts", chapters: 28, testament: .new),
        .init(id: 45, name: "Romans",          abbreviation: "Rom",  chapters: 16, testament: .new),
        .init(id: 46, name: "1 Corinthians",   abbreviation: "1Cor", chapters: 16, testament: .new),
        .init(id: 47, name: "2 Corinthians",   abbreviation: "2Cor", chapters: 13, testament: .new),
        .init(id: 48, name: "Galatians",       abbreviation: "Gal",  chapters: 6,  testament: .new),
        .init(id: 49, name: "Ephesians",       abbreviation: "Eph",  chapters: 6,  testament: .new),
        .init(id: 50, name: "Philippians",     abbreviation: "Phil", chapters: 4,  testament: .new),
        .init(id: 51, name: "Colossians",      abbreviation: "Col",  chapters: 4,  testament: .new),
        .init(id: 52, name: "1 Thessalonians", abbreviation: "1Thess", chapters: 5, testament: .new),
        .init(id: 53, name: "2 Thessalonians", abbreviation: "2Thess", chapters: 3, testament: .new),
        .init(id: 54, name: "1 Timothy",       abbreviation: "1Tim", chapters: 6,  testament: .new),
        .init(id: 55, name: "2 Timothy",       abbreviation: "2Tim", chapters: 4,  testament: .new),
        .init(id: 56, name: "Titus",           abbreviation: "Titus", chapters: 3, testament: .new),
        .init(id: 57, name: "Philemon",        abbreviation: "Phlm", chapters: 1,  testament: .new),
        .init(id: 58, name: "Hebrews",         abbreviation: "Heb",  chapters: 13, testament: .new),
        .init(id: 59, name: "James",           abbreviation: "Jas",  chapters: 5,  testament: .new),
        .init(id: 60, name: "1 Peter",         abbreviation: "1Pet", chapters: 5,  testament: .new),
        .init(id: 61, name: "2 Peter",         abbreviation: "2Pet", chapters: 3,  testament: .new),
        .init(id: 62, name: "1 John",          abbreviation: "1John", chapters: 5, testament: .new),
        .init(id: 63, name: "2 John",          abbreviation: "2John", chapters: 1, testament: .new),
        .init(id: 64, name: "3 John",          abbreviation: "3John", chapters: 1, testament: .new),
        .init(id: 65, name: "Jude",            abbreviation: "Jude", chapters: 1,  testament: .new),
        .init(id: 66, name: "Revelation",      abbreviation: "Rev",  chapters: 22, testament: .new),
    ]

    private static let byID: [Int: BibleBook] = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })

    static func book(id: Int) -> BibleBook {
        byID[id] ?? books[0]
    }

    static func book(named name: String) -> BibleBook? {
        let target = name.lowercased()
        return books.first { $0.name.lowercased() == target || $0.abbreviation.lowercased() == target }
    }

    /// The next chapter after the given reference, rolling over book boundaries.
    static func next(after ref: ChapterReference) -> ChapterReference? {
        let b = book(id: ref.bookID)
        if ref.chapter < b.chapters {
            return ChapterReference(bookID: ref.bookID, chapter: ref.chapter + 1)
        }
        if ref.bookID < books.count {
            return ChapterReference(bookID: ref.bookID + 1, chapter: 1)
        }
        return nil
    }

    /// The previous chapter before the given reference, rolling over backwards.
    static func previous(before ref: ChapterReference) -> ChapterReference? {
        if ref.chapter > 1 {
            return ChapterReference(bookID: ref.bookID, chapter: ref.chapter - 1)
        }
        if ref.bookID > 1 {
            let prev = book(id: ref.bookID - 1)
            return ChapterReference(bookID: prev.id, chapter: prev.chapters)
        }
        return nil
    }
}
