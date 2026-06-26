import Foundation
import MyMemoCore

// Lightweight CLI test runner — exits non-zero on first failure.
// Mirrors the swift-testing suite in Tests/ for environments (CLT-only) that
// cannot host .xctest bundles.

var failures = 0
var passed = 0

@MainActor
func check(_ name: String, _ condition: Bool) {
    if condition {
        passed += 1
        print("  ✔ \(name)")
    } else {
        failures += 1
        print("  ✘ \(name)")
    }
}

func todo(
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

print("HighlightRule:")
check("important sorts first",
      HighlightRule.highlighted(from: [todo("plain"), todo("starred", important: true, created: 10)])
        .map(\.text) == ["starred", "plain"])
check("due date ascending within tier",
      HighlightRule.highlighted(from: [todo("later", due: 1000), todo("sooner", due: 100)])
        .map(\.text) == ["sooner", "later"])
check("nil due date sorts last within tier",
      HighlightRule.highlighted(from: [todo("nodue", due: nil), todo("hasdue", due: 500, created: 10)])
        .map(\.text) == ["hasdue", "nodue"])
check("completed excluded",
      HighlightRule.highlighted(from: [todo("done", done: true), todo("active")])
        .map(\.text) == ["active"])
check("cap respected",
      HighlightRule.highlighted(from: (0..<20).map { todo("t\($0)", created: TimeInterval($0)) }, max: 5)
        .count == 5)
check("empty input", HighlightRule.highlighted(from: []).isEmpty)
check("important beats earlier due date",
      HighlightRule.highlighted(from: [todo("u", due: 10), todo("imp", important: true, due: 9999)])
        .first?.text == "imp")
check("createdAt tiebreaker",
      HighlightRule.highlighted(from: [todo("second", due: 100, created: 50), todo("first", due: 100, created: 10)])
        .map(\.text) == ["first", "second"])

print("Persistence:")
let dir = FileManager.default.temporaryDirectory.appendingPathComponent("mymemo-check-\(UUID().uuidString)", isDirectory: true)
let url = dir.appendingPathComponent("data.json")
defer { try? FileManager.default.removeItem(at: dir) }

let manager = PersistenceManager(fileURL: url)
var data = AppData()
data.todos = [Todo(text: "buy milk", isImportant: true), Todo(text: "call mom", dueDate: Date(timeIntervalSince1970: 1_000_000))]
data.memo = Memo(text: "remember to breathe")
manager.save(data)
let loaded = manager.load()
check("round-trip todo count", loaded.todos.count == 2)
check("round-trip first text", loaded.todos.first?.text == "buy milk")
check("round-trip importance", loaded.todos.first?.isImportant == true)
check("round-trip memo", loaded.memo.text == "remember to breathe")
check("round-trip preserves id", loaded.todos.first?.id == data.todos.first?.id)

let empty = PersistenceManager(fileURL: FileManager.default.temporaryDirectory
    .appendingPathComponent("missing-\(UUID().uuidString).json")).load()
check("missing file returns empty", empty.todos.isEmpty && empty.memo.text == "")

print("")
print("\(passed) passed, \(failures) failed")
if failures > 0 { exit(1) }
