import Foundation
import GRDB

protocol FlowRepository {
    func save(_ flow: Flow) throws
    func findById(_ id: UUID) throws -> Flow?
    func findAll(limit: Int) throws -> [Flow]
    func countAll() throws -> Int
    func findTodoFlows(limit: Int) throws -> [Flow]
    func delete(_ id: UUID) throws
    func softDelete(_ id: UUID) throws
    func countByStatus(_ status: FlowStatus) throws -> Int
}

final class FlowRepositoryImpl: FlowRepository {
    private var dbQueue: DatabaseQueue? {
        return DatabaseManager.shared.database
    }

    func save(_ flow: Flow) throws {
        guard let dbQueue = dbQueue else {
            // Fallback to in-memory queue if database unavailable
            DatabaseManager.shared.addToFallbackQueue(flow)
            return
        }

        do {
            try dbQueue.write { db in
                try flow.save(db)
            }
        } catch {
            // On failure, add to fallback queue for retry later
            DatabaseManager.shared.addToFallbackQueue(flow)
            throw error
        }
    }

    func findById(_ id: UUID) throws -> Flow? {
        guard let dbQueue = dbQueue else { return nil }

        return try dbQueue.read { db in
            try Flow.fetchOne(db, key: id)
        }
    }

    func findAll(limit: Int) throws -> [Flow] {
        guard let dbQueue = dbQueue else { return [] }

        return try dbQueue.read { db in
            try Flow
                .filter(Flow.Columns.deletedAt == nil)
                .order(
                    // Keep incomplete tasks first, then completed ones
                    SQL("CASE WHEN status = 'todo' THEN 0 ELSE 1 END"),
                    Flow.Columns.createdAt.desc
                )
                .limit(limit)
                .fetchAll(db)
        }
    }

    func countAll() throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }

        return try dbQueue.read { db in
            try Flow
                .filter(Flow.Columns.deletedAt == nil)
                .fetchCount(db)
        }
    }

    func findTodoFlows(limit: Int) throws -> [Flow] {
        guard let dbQueue = dbQueue else { return [] }

        return try dbQueue.read { db in
            try Flow
                .filter(Flow.Columns.status == FlowStatus.todo.rawValue)
                .filter(Flow.Columns.deletedAt == nil)
                .order(Flow.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func delete(_ id: UUID) throws {
        guard let dbQueue = dbQueue else { return }

        try dbQueue.write { db in
            _ = try Flow.deleteOne(db, key: id)
        }
    }

    func softDelete(_ id: UUID) throws {
        guard let dbQueue = dbQueue else { return }

        try dbQueue.write { db in
            if var flow = try Flow.fetchOne(db, key: id) {
                flow.deletedAt = Date()
                try flow.save(db)
            }
        }
    }

    func countByStatus(_ status: FlowStatus) throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }

        return try dbQueue.read { db in
            try Flow
                .filter(Flow.Columns.status == status.rawValue)
                .filter(Flow.Columns.deletedAt == nil)
                .fetchCount(db)
        }
    }
}
