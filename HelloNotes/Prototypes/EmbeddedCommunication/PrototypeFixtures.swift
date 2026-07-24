#if os(iOS)
import ExyteChat
import Foundation

enum PrototypeFixtures {
    static let aiMessages: [PrototypeAIMessage] = [
        PrototypeAIMessage(
            role: .user,
            markdown: "Turn the opening section into a concise research summary and keep the references visible."
        ),
        PrototypeAIMessage(
            role: .assistant,
            markdown: """
            ## Proposed summary

            The note distinguishes the **shared conclusion** from the open questions that still require evidence. It can be tightened into three short paragraphs while preserving the cited sources.

            Nothing has been written to the document. Use the preview card below to inspect a mock diff.
            """,
            reasoning: [
                "Read the local note title, collection label, and excerpt supplied by the prototype host context.",
                "Grouped the opening ideas into a conclusion, supporting evidence, and unresolved questions.",
                "Prepared a visual edit preview without touching the editor buffer or autosave flow."
            ],
            citations: [
                PrototypeAICitation(
                    id: "research-notes",
                    title: "Research Notes.md",
                    detail: "Opening section in the current document"
                ),
                PrototypeAICitation(
                    id: "meeting-summary",
                    title: "Meeting Summary.md",
                    detail: "Linked background note"
                )
            ],
            toolAction: PrototypeAIToolAction(
                title: "Preparing document edit…",
                result: "3 paragraphs would be updated",
                buttonTitle: "Preview changes"
            ),
            attachment: PrototypeAIContextAttachment(
                title: "Document context",
                detail: "Title, excerpt, collection, and word count attached locally",
                systemImage: "doc.text"
            )
        )
    ]

    static let socialConversations: [PrototypeConversation] = [
        PrototypeConversation(
            id: "david-miriam",
            name: "Miriam Cohen",
            initials: "MC",
            lastMessage: "I left the citations in the shared draft.",
            time: "10:42",
            unreadCount: 0,
            kind: .direct,
            isTyping: false,
            hasDraft: false,
            isLinkedToHostContent: true
        ),
        PrototypeConversation(
            id: "writing-circle",
            name: "Writing Circle",
            initials: "WC",
            lastMessage: "Eli: I shared the research note.",
            time: "10:18",
            unreadCount: 3,
            kind: .studyGroup,
            isTyping: false,
            hasDraft: false,
            isLinkedToHostContent: true
        ),
        PrototypeConversation(
            id: "research-team",
            name: "Research Team",
            initials: "RT",
            lastMessage: "Noa is typing…",
            time: "09:54",
            unreadCount: 0,
            kind: .workGroup,
            isTyping: true,
            hasDraft: false,
            isLinkedToHostContent: true
        ),
        PrototypeConversation(
            id: "editorial-review",
            name: "Editorial Review",
            initials: "ER",
            lastMessage: "Can we compare the two versions?",
            time: "Yesterday",
            unreadCount: 7,
            kind: .workGroup,
            isTyping: false,
            hasDraft: false,
            isLinkedToHostContent: false
        ),
        PrototypeConversation(
            id: "jon-levi",
            name: "Jon Levi",
            initials: "JL",
            lastMessage: "Draft: I think the second section…",
            time: "Yesterday",
            unreadCount: 0,
            kind: .direct,
            isTyping: false,
            hasDraft: true,
            isLinkedToHostContent: false
        ),
        PrototypeConversation(
            id: "documentation",
            name: "Documentation Group",
            initials: "DG",
            lastMessage: "Sara: Updated the terminology notes.",
            time: "Mon",
            unreadCount: 0,
            kind: .studyGroup,
            isTyping: false,
            hasDraft: false,
            isLinkedToHostContent: true
        )
    ]

    static let currentUser = User(
        id: "current-user",
        name: "David",
        avatarURL: nil,
        isCurrentUser: true
    )

    static let miriam = User(
        id: "miriam",
        name: "Miriam",
        avatarURL: nil,
        isCurrentUser: false
    )

    static let eli = User(
        id: "eli",
        name: "Eli",
        avatarURL: nil,
        isCurrentUser: false
    )

    static let systemUser = User(
        id: "system",
        name: "HelloNotes",
        avatarURL: nil,
        type: .system
    )

    static let groupMessages: [ExyteChat.Message] = [
        Message(
            id: "welcome",
            user: systemUser,
            status: .read,
            createdAt: Date(timeIntervalSinceNow: -4_200),
            text: "Miriam created the writing room."
        ),
        Message(
            id: "opening",
            user: miriam,
            status: .read,
            createdAt: Date(timeIntervalSinceNow: -3_600),
            text: "The opening summary is clear, but the evidence should stay closer to each claim."
        ),
        Message(
            id: "reply",
            user: currentUser,
            status: .read,
            createdAt: Date(timeIntervalSinceNow: -3_100),
            text: "Agreed — I’ll keep the reference block immediately after it.",
            replyMessage: ReplyMessage(
                id: "opening",
                user: miriam,
                createdAt: Date(timeIntervalSinceNow: -3_600),
                text: "The opening summary is clear, but the evidence should stay closer to each claim."
            )
        ),
        Message(
            id: "long-message",
            user: eli,
            status: .read,
            createdAt: Date(timeIntervalSinceNow: -2_400),
            text: "The longer structure works if we treat the conclusion, the supporting notes, and the unresolved questions as one sequence. That keeps the document useful both as a record and as a plan for the next session.",
            reactions: [
                Reaction(user: currentUser, type: .emoji("👍"), status: .sent),
                Reaction(user: miriam, type: .emoji("✍️"), status: .sent)
            ]
        ),
        Message(
            id: "resource-card",
            user: miriam,
            status: .read,
            createdAt: Date(timeIntervalSinceNow: -1_500),
            text: "Shared a note",
            customData: [
                "prototypeCardKind": PrototypeSocialCardKind.resource.rawValue
            ]
        ),
        Message(
            id: "image-card",
            user: eli,
            status: .read,
            createdAt: Date(timeIntervalSinceNow: -900),
            text: "Whiteboard after the workshop",
            customData: [
                "prototypeCardKind": PrototypeSocialCardKind.image.rawValue
            ]
        ),
        Message(
            id: "link",
            user: currentUser,
            status: .delivered,
            createdAt: Date(timeIntervalSinceNow: -420),
            text: "This outline may help: https://example.com/writing-outline"
        )
    ]
}
#endif
