import Testing
import Foundation
@testable import MyMemoCore

@Suite struct PersistenceTests {

    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("mymemo-test-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("data.json")
    }

    @Test func roundTrip() {
        let url = tempFileURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let manager = PersistenceManager(fileURL: url)
        var data = AppData()
        data.todos = [
            Todo(text: "buy milk", isImportant: true),
            Todo(text: "call mom", dueDate: Date(timeIntervalSince1970: 1_000_000))
        ]
        data.memo = Memo(text: "remember to breathe")

        manager.save(data)
        let loaded = manager.load()

        #expect(loaded.todos.count == 2)
        #expect(loaded.todos.first?.text == "buy milk")
        #expect(loaded.todos.first?.isImportant == true)
        #expect(loaded.memo.text == "remember to breathe")
    }

    @Test func loadMissingFileReturnsEmpty() {
        let manager = PersistenceManager(fileURL: tempFileURL())
        let loaded = manager.load()
        #expect(loaded.todos.isEmpty)
        #expect(loaded.memo.text == "")
    }

    @Test func equatableRoundTripPreservesIdentity() {
        let url = tempFileURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let manager = PersistenceManager(fileURL: url)
        let original = AppData(todos: [Todo(text: "x")], memo: Memo(text: "y"))
        manager.save(original)
        let loaded = manager.load()
        #expect(loaded.todos.first?.id == original.todos.first?.id)
    }
}
