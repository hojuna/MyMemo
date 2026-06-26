import Testing
import Foundation
@testable import MyMemoCore

private func todo(
    _ text: String,
    important: Bool = false,
    due: TimeInterval? = nil,
    done: Bool = false,
    created: TimeInterval = 0
) -> Todo {
    let base = Date(timeIntervalSinceReferenceDate: 0)
    return Todo(
        text: text,
        isImportant: important,
        dueDate: due.map { base.addingTimeInterval($0) },
        isDone: done,
        createdAt: base.addingTimeInterval(created)
    )
}

@Suite struct HighlightRuleTests {

    @Test func importantSortsFirst() {
        let result = HighlightRule.highlighted(from: [
            todo("plain", important: false, created: 0),
            todo("starred", important: true, created: 10)
        ])
        #expect(result.map(\.text) == ["starred", "plain"])
    }

    @Test func dueDateAscendingWithinTier() {
        let result = HighlightRule.highlighted(from: [
            todo("later", due: 1000),
            todo("sooner", due: 100)
        ])
        #expect(result.map(\.text) == ["sooner", "later"])
    }

    @Test func nilDueDateSortsLastWithinTier() {
        let result = HighlightRule.highlighted(from: [
            todo("nodue", due: nil, created: 0),
            todo("hasdue", due: 500, created: 10)
        ])
        #expect(result.map(\.text) == ["hasdue", "nodue"])
    }

    @Test func completedExcluded() {
        let result = HighlightRule.highlighted(from: [
            todo("done", done: true),
            todo("active", done: false)
        ])
        #expect(result.map(\.text) == ["active"])
    }

    @Test func capRespected() {
        let many = (0..<20).map { todo("t\($0)", created: TimeInterval($0)) }
        let result = HighlightRule.highlighted(from: many, max: 5)
        #expect(result.count == 5)
    }

    @Test func emptyInput() {
        #expect(HighlightRule.highlighted(from: []).isEmpty)
    }

    @Test func importantBeatsEarlierDueDate() {
        let result = HighlightRule.highlighted(from: [
            todo("urgent-not-important", important: false, due: 10),
            todo("important-later", important: true, due: 9999)
        ])
        #expect(result.first?.text == "important-later")
    }

    @Test func createdAtTiebreaker() {
        let result = HighlightRule.highlighted(from: [
            todo("second", due: 100, created: 50),
            todo("first", due: 100, created: 10)
        ])
        #expect(result.map(\.text) == ["first", "second"])
    }
}
