#if os(iOS)
import Foundation

struct PrototypeHostContext: Equatable, Sendable {
    let title: String
    let identifier: String
    let collectionName: String?
    let excerpt: String?
    let detail: String?
    let hasDocumentContext: Bool

    var compactTitle: String {
        hasDocumentContext ? "Current context: \(title)" : "No note open"
    }

    var accessibilitySummary: String {
        [
            title,
            collectionName,
            detail,
            excerpt
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
#endif

