#if os(iOS)
import SwiftUI

struct SocialResourceCard: View {
    let kind: PrototypeSocialCardKind
    let onAction: (String) -> Void

    var body: some View {
        Group {
            switch kind {
            case .resource:
                resourceCard
            case .image:
                imageCard
            }
        }
        .frame(maxWidth: 360)
        .padding(.vertical, 4)
    }

    private var resourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 42, height: 42)
                    .background(.tint.opacity(0.12), in: .rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Research Notes.md")
                        .font(.headline)
                    Text("“Summary of the discussion…”")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Text("Shared from HelloNotes")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Open note") {
                    onAction("Would open Research Notes.md in HelloNotes.")
                }
                .buttonStyle(.bordered)
                Button("Insert reference") {
                    onAction("Would preview a local reference insertion.")
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.small)
        }
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }

    private var imageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(
                    colors: [.indigo.opacity(0.78), .cyan.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    .font(.system(size: 46))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(height: 150)
            .clipShape(.rect(cornerRadius: 14))

            Text("Whiteboard after the workshop")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mock image of a workshop whiteboard")
    }
}
#endif

