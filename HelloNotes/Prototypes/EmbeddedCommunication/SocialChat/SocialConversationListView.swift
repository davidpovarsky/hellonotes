#if os(iOS)
import SwiftUI

struct SocialConversationListView: View {
    let presentation: PrototypeSurfacePresentation
    @Binding var navigationPath: NavigationPath
    var viewModel: SocialChatViewModel
    let onClose: () -> Void

    init(
        presentation: PrototypeSurfacePresentation = .modal,
        navigationPath: Binding<NavigationPath> = .constant(NavigationPath()),
        viewModel: SocialChatViewModel = SocialChatViewModel(),
        onClose: @escaping () -> Void
    ) {
        self.presentation = presentation
        _navigationPath = navigationPath
        self.viewModel = viewModel
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if presentation == .modal {
                    conversationList
                        .navigationTitle("Social Chat")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done", action: onClose)
                                    .accessibilityLabel("Close")
                            }
                        }
                } else {
                    conversationList
                }
            }
            .navigationDestination(for: PrototypeConversation.self) { conversation in
                SocialRoomView(conversation: conversation, viewModel: viewModel)
            }
        }
    }

    private var conversationList: some View {
        List(PrototypeFixtures.socialConversations) { conversation in
            NavigationLink(value: conversation) {
                SocialConversationRow(conversation: conversation)
            }
        }
        .listStyle(.plain)
    }
}

#Preview("Conversation list") {
    SocialConversationListView(onClose: {})
}
#endif
