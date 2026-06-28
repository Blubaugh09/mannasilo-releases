import SwiftUI

/// The five-tab spine of the app: read, ask, notes, glasses, settings.
struct RootView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        TabView {
            ReaderView()
                .tabItem { Label("Read", systemImage: "book.closed") }

            AskView()
                .tabItem { Label("Ask", systemImage: "sparkles") }

            NotesView()
                .tabItem { Label("Notes", systemImage: "note.text") }

            GlassesView()
                .tabItem { Label("Glasses", systemImage: "eyeglasses") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
