#if os(iOS)
import SwiftUI

struct SocialConversationListView: View {
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List(PrototypeFixtures.socialConversations) { conversation in
                NavigationLink(value: conversation) {
                    SocialConversationRow(conversation: conversation)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Social Chat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PrototypeConversation.self) { conversation in
                SocialRoomView(conversation: conversation)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onClose)
                        .accessibilityLabel("Close")
                }
            }
        }
    }
}

#Preview("Conversation list") {
    SocialConversationListView(onClose: {})
}
#endif

