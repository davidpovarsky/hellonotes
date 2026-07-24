# Embedded AI and social chat prototype

## Purpose

This branch is a visual, interactive iPhone/iPad experiment that embeds two local-only communication surfaces in HelloNotes:

- an AI assistant informed by the current note, collection, excerpt, and document metrics;
- a social conversation list and Exyte Chat room with HelloNotes document cards.

There is no backend, user login, Matrix integration, AI provider, API key, shared database, CloudKit/App Group/Keychain sharing, push notification, or new network request. Sending, streaming, citations, edit preview, note opening, voice input, attachments, and tool actions are mock interactions backed by in-memory fixtures.

## Source and experiment branches

- Source branch: `codex/hellonotes-full-ci-20260720-220842`
- Source HEAD: `3ff817193848f33afe649ab4534ca9a64c488bc6`
- Experiment branch: `codex/prototype-embedded-ai-social-chat-20260724`

## Open-source references

- SwiftChat visual/interaction reference: `sachaservan/SwiftChat` at `d6f54ccf9e84d2fec672b7b89d5a67dd6ee0f957`
- Exyte Chat Swift package: `exyte/Chat` at exact revision `554a0798e424ff15440d5af3b675cc9a5e65b759`
- SwiftChat attribution: `HelloNotes/Prototypes/EmbeddedCommunication/SwiftChat-ATTRIBUTION.md`

The SwiftChat entry point, storage, API-key handling, network layer, OpenAI integration, and bundle configuration were intentionally not included.

## Added files

- `HelloNotes/Prototypes/EmbeddedCommunication/PrototypeCommunicationModels.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/PrototypeFixtures.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/PrototypeHostContext.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/SwiftChat-ATTRIBUTION.md`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAIChatView.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAIChatViewModel.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAIMessageView.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAIComposer.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAIReasoningView.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAICitationView.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAIToolCard.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/EmbeddedAI/EmbeddedAIContextHeader.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/SocialChat/SocialConversationListView.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/SocialChat/SocialConversationRow.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/SocialChat/SocialRoomView.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/SocialChat/SocialResourceCard.swift`
- `HelloNotes/Prototypes/EmbeddedCommunication/SocialChat/SocialChatViewModel.swift`

## Existing files changed

- `HelloNotes/iOSContentView.swift` — adds two detail-toolbar buttons, local sheet state, and a read-only host-context bridge.
- `HelloNotes.xcodeproj/project.pbxproj` — adds the exact Exyte Chat package/product, with the framework build file filtered to iOS.

All prototype Swift files are wrapped in `#if os(iOS)`. The editor, selection behavior, document writes, and autosave flow were not changed.

## How to open the prototype

1. Launch the iOS app and open a collection.
2. In the detail toolbar:
   - tap `sparkles` to open **AI Assistant**;
   - tap `bubble.left.and.bubble.right` to open **Social Chat**.
3. AI Assistant remains available without a selected note and shows the no-document context state.
4. In Social Chat, select **Writing Circle** to see the Exyte Chat room and document resource card.

## Mock-only behavior

- AI responses stream from a local string with `Task.sleep`; **Stop** cancels the local task.
- Reasoning text is illustrative UI copy, not model chain-of-thought.
- Citations, edit previews, note opening, attachments, and microphone actions are simulated.
- Social conversations and messages live only in memory.
- Resource-card buttons show local prototype feedback and never edit the document.

## Intentionally not implemented

- Backend, authentication, Matrix, Firebase, AI-provider calls, API keys, persistence, synchronization, real attachments/recording, notifications, and network transport.
- Writes to notes, changes to the editor engine, selection plumbing, autosave, or macOS UI.

## Removal

1. Remove `HelloNotes/Prototypes/EmbeddedCommunication/`.
2. Revert the prototype-only additions in `HelloNotes/iOSContentView.swift`.
3. Remove the `D0EC…` Exyte Chat package/product entries from `HelloNotes.xcodeproj/project.pbxproj`.
4. Delete this document.

## Screenshots

Not produced in the Windows editing environment. Simulator screenshots should be captured from the verified Xcode build if a macOS runner or local Mac simulator is available.

## Build results

Pending GitHub Actions verification for both iOS and macOS through the repository’s existing unsigned-build scripts.
