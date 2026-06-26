import Foundation
import Observation

/// Single source of truth for the whole app. Observed by both the floating
/// panel and the editor window. `@MainActor` because all UI reads/writes it.
@MainActor
@Observable
public final class AppStore {

    /// Shared singleton — injected into both UI hierarchies.
    public static let shared = AppStore()

    public private(set) var data: AppData

    private let persistence: PersistenceManager
    private let debounceInterval: Duration
    private var saveTask: Task<Void, Never>?

    public init(
        persistence: PersistenceManager = .shared,
        debounceInterval: Duration = .seconds(0.5),
        loadOnInit: Bool = true
    ) {
        self.persistence = persistence
        self.debounceInterval = debounceInterval
        self.data = loadOnInit ? persistence.load() : AppData()
    }

    // MARK: - Derived

    /// Todos selected for the read-only panel via the highlight rule.
    public var highlightedTodos: [Todo] {
        HighlightRule.highlighted(from: data.todos)
    }

    // MARK: - Mutations

    public func addTodo(_ text: String, isImportant: Bool = false, dueDate: Date? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        data.todos.append(Todo(text: trimmed, isImportant: isImportant, dueDate: dueDate))
        scheduleSave()
    }

    public func updateText(_ id: UUID, text: String) {
        guard let i = index(of: id) else { return }
        data.todos[i].text = text
        scheduleSave()
    }

    public func updateDueDate(_ id: UUID, dueDate: Date?) {
        guard let i = index(of: id) else { return }
        data.todos[i].dueDate = dueDate
        scheduleSave()
    }

    public func toggleDone(_ id: UUID) {
        guard let i = index(of: id) else { return }
        data.todos[i].isDone.toggle()
        scheduleSave()
    }

    public func toggleImportant(_ id: UUID) {
        guard let i = index(of: id) else { return }
        data.todos[i].isImportant.toggle()
        scheduleSave()
    }

    public func deleteTodo(_ id: UUID) {
        data.todos.removeAll { $0.id == id }
        scheduleSave()
    }

    public func updateMemo(_ text: String) {
        data.memo.text = text
        scheduleSave()
    }

    // MARK: - Persistence

    /// Debounced save: cancel any pending save, capture a Sendable snapshot,
    /// then persist after the debounce interval off the main actor.
    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = data            // value-type copy, Sendable
        let interval = debounceInterval
        let manager = persistence
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(for: interval)
            if Task.isCancelled { return }
            manager.save(snapshot)
        }
    }

    /// Synchronous immediate save — call on app termination.
    public func saveNow() {
        saveTask?.cancel()
        persistence.save(data)
    }

    private func index(of id: UUID) -> Int? {
        data.todos.firstIndex { $0.id == id }
    }
}
