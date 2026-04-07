import Foundation

final class TaskManager {
    static let shared = TaskManager()

    private let repository: TaskRepository

    private init() {
        self.repository = TaskRepositoryImpl()
    }

    func addTask(content: String) -> Result<Task, Error> {
        let task = Task(content: content)
        do {
            try repository.save(task)
            return .success(task)
        } catch {
            return .failure(error)
        }
    }

    func completeTask(id: UUID) throws {
        guard var task = try repository.findById(id) else {
            throw TaskError.notFound
        }
        task.status = .done
        task.completedAt = Date()
        try repository.save(task)
    }

    func undoComplete(id: UUID) throws {
        guard var task = try repository.findById(id) else {
            throw TaskError.notFound
        }
        task.status = .todo
        task.completedAt = nil
        try repository.save(task)
    }

    func deleteTask(id: UUID) throws {
        try repository.softDelete(id)
    }

    func fetchTasks(limit: Int = 5) -> [Task] {
        do {
            return try repository.findTodoTasks(limit: limit)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
}

enum TaskError: Error {
    case notFound
    case validationFailed(String)
}
