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
- `HelloNotes/Prototypes/EmbeddedCommunication/HelloNotesCommunicationInspectorView.swift`
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
- `scripts/ci/verify-embedded-frameworks.sh`

## Existing files changed

- `HelloNotes/iOSContentView.swift` — removes the two communication sheets and attaches one communication inspector to the root `NavigationSplitView`.
- `EmbeddedAIChatView.swift`, `SocialConversationListView.swift`, and `SocialRoomView.swift` — add an embedded inspector presentation while retaining modal previews.
- `scripts/ci/build-ios-unsigned.sh` — verifies device and simulator runtime dependencies, builds and launches the simulator app, and captures launch evidence.
- `scripts/ci/build-macos-unsigned.sh` — verifies the macOS dependency graph and explicitly rejects Giphy linkage or embedding.

All prototype Swift files are wrapped in `#if os(iOS)`. Exyte Chat remains filtered to iOS, and Giphy is not added to the macOS target. The editor, selection behavior, document writes, and autosave flow were not changed.

## Inspector architecture and state

The root iOS `NavigationSplitView` owns one `.inspector` with **AI / Chats** sections and a 320/400/520-point column width. The existing `sparkles` and `bubble.left.and.bubble.right` toolbar buttons select a section in that inspector; selecting the already-open section closes it.

The inspector host owns stable AI and social view models plus the social `NavigationPath`. Switching sections therefore preserves the AI transcript/streaming task, selected chat room, mock messages, and social navigation. Streaming stops only on an explicit Stop action or when the whole inspector disappears/closes.

`prototypeHostContext` remains computed by `iOSContentView` from the current editor note, collection, text excerpt, word count, and character count. Passing updated context into the same host refreshes the context header when the note or text changes without replacing the host-owned conversation state. With no note open it supplies the existing empty-context model.

## How to open the prototype

1. Launch the iOS app and open a collection and note.
2. In the detail toolbar:
   - tap `sparkles` to open the inspector on **AI**;
   - tap `bubble.left.and.bubble.right` to open the same inspector on **Chats**.
3. Switch with the **AI / Chats** segmented control while continuing to edit or change Edit/Markdown/Split mode.
4. AI remains available without a selected note and shows the no-document context state.
5. In Chats, select **Writing Circle** to see the Exyte Chat room and document resource card.

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
2. Revert the prototype-only inspector additions in `HelloNotes/iOSContentView.swift`.
3. Remove the `D0EC…` Exyte Chat package/product entries from `HelloNotes.xcodeproj/project.pbxproj`.
4. Delete this document.

## Screenshots

The final iOS diagnostics contain `launch-simulator.png`, captured after the app was installed and launched on the CI simulator. Inspector-state screenshots were not captured because the ephemeral runner has no seeded user collection/note and the app has no UI-test fixture path for those states.

## Build results

- Final runtime verification: [HelloNotes CI and Unsigned Builds run 30093211758](https://github.com/davidpovarsky/hellonotes/actions/runs/30093211758) succeeded for commit `39d9040c9f1d0787ee322a0073f96640601b7862`.
- Environment: `macos-26`, Xcode 26.5, `HelloNotes` scheme, Release device archive plus Debug simulator build.
- `bash scripts/ci/build-ios-unsigned.sh` created the unsigned IPA, verified the device app and IPA contents, built the simulator product, recursively verified its `@rpath` dependencies, installed it, and launched `com.hellotham.HelloNotes`. Launch output was `com.hellotham.HelloNotes: 49914`, and the workflow confirmed that PID 49914 remained alive after ten seconds.
- The iOS app and IPA contain `Frameworks/GiphyUISDK.framework/GiphyUISDK`; the verifier also inspected BeautifulMermaid and ElkSwift package frameworks.
- `bash scripts/ci/build-macos-unsigned.sh` succeeded. Its verifier inspected the macOS main executable and embedded frameworks, while explicit checks confirmed that the app neither contains nor references `GiphyUISDK`.
- Distribution and diagnostics artifacts include the unsigned iOS IPA/archive, unsigned macOS app/archive, dependency logs, IPA contents, simulator launch output, system log, and launch screenshot.
- An earlier diagnostic run selected an iOS 26.4.1 simulator for an app whose minimum version is 26.5. The script now deterministically selects an iPhone from the newest available iOS runtime; the final run installed and launched successfully.
