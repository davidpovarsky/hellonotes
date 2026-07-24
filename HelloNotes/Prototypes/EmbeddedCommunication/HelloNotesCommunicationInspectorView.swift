#if os(iOS)
import SwiftUI

enum HelloNotesInspectorSection: String, CaseIterable, Identifiable {
    case assistant
    case socialChat

    var id: Self { self }

    var title: String {
        switch self {
        case .assistant: "AI"
        case .socialChat: "Chats"
        }
    }

    var systemImage: String {
        switch self {
        case .assistant: "sparkles"
        case .socialChat: "bubble.left.and.bubble.right"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .assistant: "AI Assistant"
        case .socialChat: "Social Chat"
        }
    }
}

struct HelloNotesCommunicationInspectorView: View {
    let context: PrototypeHostContext
    @Binding var selectedSection: HelloNotesInspectorSection
    let onClose: () -> Void

    @State private var aiViewModel = EmbeddedAIChatViewModel()
    @State private var socialViewModel = SocialChatViewModel()
    @State private var socialNavigationPath = NavigationPath()

    var body: some View {
        VStack(spacing: 0) {
            inspectorHeader
            Divider()
            inspectorContent
        }
        .background(Color(uiColor: .systemBackground))
        .onDisappear {
            aiViewModel.stopStreaming()
        }
    }

    private var inspectorHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Communication")
                    .font(.headline)
                Spacer()
                Button(action: closeInspector) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Inspector")
            }

            Picker("Inspector section", selection: $selectedSection) {
                ForEach(HelloNotesInspectorSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .accessibilityLabel(section.accessibilityLabel)
                        .tag(section)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch selectedSection {
        case .assistant:
            EmbeddedAIChatView(
                context: context,
                presentation: .inspector,
                viewModel: aiViewModel,
                onClose: closeInspector
            )
        case .socialChat:
            SocialConversationListView(
                presentation: .inspector,
                navigationPath: $socialNavigationPath,
                viewModel: socialViewModel,
                onClose: closeInspector
            )
        }
    }

    private func closeInspector() {
        aiViewModel.stopStreaming()
        onClose()
    }
}
#endif
