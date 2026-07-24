#if os(iOS)
import Foundation
import Observation

@MainActor
@Observable
final class EmbeddedAIChatViewModel {
    var messages: [PrototypeAIMessage]
    var composerText = ""
    var pendingAttachment: PrototypeAIContextAttachment?
    var isStreaming = false
    var notice: String?

    private var streamingTask: Task<Void, Never>?

    init(messages: [PrototypeAIMessage]? = nil) {
        self.messages = messages ?? PrototypeFixtures.aiMessages
    }

    func startNewConversation() {
        stopStreaming()
        messages = []
        composerText = ""
        pendingAttachment = nil
    }

    func toggleContextAttachment() {
        if pendingAttachment == nil {
            pendingAttachment = PrototypeAIContextAttachment(
                title: "Current note excerpt",
                detail: "Local document context only",
                systemImage: "doc.text"
            )
        } else {
            pendingAttachment = nil
        }
    }

    func simulateMicrophone() {
        notice = "Voice input is a visual prototype and did not record audio."
    }

    func send(context: PrototypeHostContext) {
        let trimmed = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        messages.append(
            PrototypeAIMessage(
                role: .user,
                markdown: trimmed,
                attachment: pendingAttachment
            )
        )
        composerText = ""
        pendingAttachment = nil

        let responseID = UUID()
        messages.append(
            PrototypeAIMessage(
                id: responseID,
                role: .assistant,
                markdown: "",
                reasoning: [
                    "Read the local document context supplied by HelloNotes.",
                    "Prepared a short mock edit preview without writing to the note."
                ],
                citations: context.hasDocumentContext ? [
                    PrototypeAICitation(
                        id: "current-note",
                        title: context.title,
                        detail: context.detail ?? "Current document context"
                    )
                ] : [],
                toolAction: PrototypeAIToolAction(
                    title: "Preparing document edit…",
                    result: "3 paragraphs would be updated",
                    buttonTitle: "Preview changes"
                )
            )
        )

        let response = context.hasDocumentContext
            ? """
              **Mock edit preview:** The opening can be condensed into a conclusion, two supporting observations, and one explicit open question.

              No document content was changed. This response used local fixture data only.
              """
            : """
              Open a note to give the assistant document context.

              You can still explore this local prototype without a network connection.
              """

        isStreaming = true
        streamingTask?.cancel()
        streamingTask = Task { [weak self] in
            guard let self else { return }
            for word in response.split(separator: " ", omittingEmptySubsequences: false) {
                if Task.isCancelled { break }
                try? await Task.sleep(for: .milliseconds(34))
                if Task.isCancelled { break }
                guard let index = messages.firstIndex(where: { $0.id == responseID }) else { break }
                messages[index].markdown += messages[index].markdown.isEmpty ? String(word) : " \(word)"
            }

            if let index = messages.firstIndex(where: { $0.id == responseID }),
               messages[index].markdown.isEmpty {
                messages.remove(at: index)
            }
            isStreaming = false
            streamingTask = nil
        }
    }

    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        if let last = messages.last, last.role == .assistant, last.markdown.isEmpty {
            messages.removeLast()
        }
        isStreaming = false
    }
}
#endif
