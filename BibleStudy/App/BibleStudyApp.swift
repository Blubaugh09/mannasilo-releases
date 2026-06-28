import SwiftUI
import SwiftData

@main
struct BibleStudyApp: App {

    // Shared, app-lifetime state.
    @StateObject private var settings = SettingsStore()
    @StateObject private var glasses = GlassesManager()

    // SwiftData container for notes, highlights, and reading position.
    let modelContainer: ModelContainer = {
        let schema = Schema([StudyNote.self, VerseHighlight.self, ReadingPosition.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(glasses)
                .tint(settings.accent.color)
                .modelContainer(modelContainer)
        }
    }
}
