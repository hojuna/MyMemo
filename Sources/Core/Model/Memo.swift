import Foundation

/// A single free-form memo (one text block).
public struct Memo: Codable, Equatable, Sendable {
    public var text: String

    public init(text: String = "") {
        self.text = text
    }
}
