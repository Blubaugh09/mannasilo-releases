import SwiftUI

/// The Ask tab — a free-form conversation with Claude about scripture.
struct AskView: View {
    var body: some View {
        NavigationStack {
            AskConversationView()
                .navigationTitle("Ask")
        }
    }
}
