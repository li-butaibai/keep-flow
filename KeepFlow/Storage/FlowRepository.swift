import Foundation
import GRDB

protocol FlowRepository {
    func save(_ flow: Flow) throws
    func findById(_ id: UUID) throws -> Flow?
    func findAll(limit: Int) throws -> [Flow]
    func findVisibleFlows(limit: Int, now: Date) throws -> [Flow]
    func countVisibleFlows(now: Date) throws -> Int
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
                .order(Flow.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
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

    func findVisibleFlows(limit: Int, now: Date) throws -> [Flow] {
        guard let dbQueue = dbQueue else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return try findTodoFlows(limit: limit)
        }

        return try dbQueue.read { db in
            try Flow
                .filter(Flow.Columns.deletedAt == nil)
                .filter(
                    (Flow.Columns.status == FlowStatus.todo.rawValue) ||
                    (
                        (Flow.Columns.status == FlowStatus.done.rawValue) &&
                        (Flow.Columns.completedAt != nil) &&
                        (Flow.Columns.completedAt >= startOfDay) &&
                        (Flow.Columns.completedAt < startOfTomorrow)
                    )
                )
                .order(
                    // Keep unfinished work first, then today's completed items.
                    SQL("CASE WHEN status = 'todo' THEN 0 ELSE 1 END"),
                    Flow.Columns.completedAt.desc,
                    Flow.Columns.createdAt.desc
                )
                .limit(limit)
                .fetchAll(db)
        }
    }

    func countVisibleFlows(now: Date) throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return try countByStatus(.todo)
        }

        return try dbQueue.read { db in
            try Flow
                .filter(Flow.Columns.deletedAt == nil)
                .filter(
                    (Flow.Columns.status == FlowStatus.todo.rawValue) ||
                    (
                        (Flow.Columns.status == FlowStatus.done.rawValue) &&
                        (Flow.Columns.completedAt != nil) &&
                        (Flow.Columns.completedAt >= startOfDay) &&
                        (Flow.Columns.completedAt < startOfTomorrow)
                    )
                )
                .fetchCount(db)
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
