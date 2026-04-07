import Foundation
import GRDB

protocol TaskRepository {
    func save(_ task: Task) throws
    func findById(_ id: UUID) throws -> Task?
    func findAll(limit: Int) throws -> [Task]
    func findTodoTasks(limit: Int) throws -> [Task]
    func delete(_ id: UUID) throws
    func softDelete(_ id: UUID) throws
    func countByStatus(_ status: TaskStatus) throws -> Int
}

final class TaskRepositoryImpl: TaskRepository {
    private var dbQueue: DatabaseQueue? {
        return DatabaseManager.shared.database
    }

    func save(_ task: Task) throws {
        guard let dbQueue = dbQueue else {
            // Fallback to in-memory queue if database unavailable
            DatabaseManager.shared.addToFallbackQueue(task)
            return
        }

        do {
            try dbQueue.write { db in
                try task.save(db)
            }
        } catch {
            // On failure, add to fallback queue for retry later
            DatabaseManager.shared.addToFallbackQueue(task)
            throw error
        }
    }

    func findById(_ id: UUID) throws -> Task? {
        guard let dbQueue = dbQueue else { return nil }

        return try dbQueue.read { db in
            try Task.fetchOne(db, key: id)
        }
    }

    func findAll(limit: Int) throws -> [Task] {
        guard let dbQueue = dbQueue else { return [] }

        return try dbQueue.read { db in
            try Task
                .filter(Task.Columns.deletedAt == nil)
                .order(Task.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func findTodoTasks(limit: Int) throws -> [Task] {
        guard let dbQueue = dbQueue else { return [] }

        return try dbQueue.read { db in
            try Task
                .filter(Task.Columns.status == TaskStatus.todo.rawValue)
                .filter(Task.Columns.deletedAt == nil)
                .order(Task.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func delete(_ id: UUID) throws {
        guard let dbQueue = dbQueue else { return }

        try dbQueue.write { db in
            _ = try Task.deleteOne(db, key: id)
        }
    }

    func softDelete(_ id: UUID) throws {
        guard let dbQueue = dbQueue else { return }

        try dbQueue.write { db in
            if var task = try Task.fetchOne(db, key: id) {
                task.deletedAt = Date()
                try task.save(db)
            }
        }
    }

    func countByStatus(_ status: TaskStatus) throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }

        return try dbQueue.read { db in
            try Task
                .filter(Task.Columns.status == status.rawValue)
                .filter(Task.Columns.deletedAt == nil)
                .fetchCount(db)
        }
    }
}
