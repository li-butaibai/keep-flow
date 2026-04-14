import Foundation
import GRDB

protocol FlashMindRepository {
    func save(_ flashMind: FlashMind) throws
    func findById(_ id: UUID) throws -> FlashMind?
    func findAll(limit: Int) throws -> [FlashMind]
    func countAll() throws -> Int
    func findTodoFlashMinds(limit: Int) throws -> [FlashMind]
    func delete(_ id: UUID) throws
    func softDelete(_ id: UUID) throws
    func countByStatus(_ status: FlashMindStatus) throws -> Int
}

final class FlashMindRepositoryImpl: FlashMindRepository {
    private var dbQueue: DatabaseQueue? {
        return DatabaseManager.shared.database
    }

    func save(_ flashMind: FlashMind) throws {
        guard let dbQueue = dbQueue else {
            // Fallback to in-memory queue if database unavailable
            DatabaseManager.shared.addToFallbackQueue(flashMind)
            return
        }

        do {
            try dbQueue.write { db in
                try flashMind.save(db)
            }
        } catch {
            // On failure, add to fallback queue for retry later
            DatabaseManager.shared.addToFallbackQueue(flashMind)
            throw error
        }
    }

    func findById(_ id: UUID) throws -> FlashMind? {
        guard let dbQueue = dbQueue else { return nil }

        return try dbQueue.read { db in
            try FlashMind.fetchOne(db, key: id)
        }
    }

    func findAll(limit: Int) throws -> [FlashMind] {
        guard let dbQueue = dbQueue else { return [] }

        return try dbQueue.read { db in
            try FlashMind
                .filter(FlashMind.Columns.deletedAt == nil)
                .order(
                    // Keep incomplete tasks first, then completed ones
                    SQL("CASE WHEN status = 'todo' THEN 0 ELSE 1 END"),
                    FlashMind.Columns.createdAt.desc
                )
                .limit(limit)
                .fetchAll(db)
        }
    }

    func countAll() throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }

        return try dbQueue.read { db in
            try FlashMind
                .filter(FlashMind.Columns.deletedAt == nil)
                .fetchCount(db)
        }
    }

    func findTodoFlashMinds(limit: Int) throws -> [FlashMind] {
        guard let dbQueue = dbQueue else { return [] }

        return try dbQueue.read { db in
            try FlashMind
                .filter(FlashMind.Columns.status == FlashMindStatus.todo.rawValue)
                .filter(FlashMind.Columns.deletedAt == nil)
                .order(FlashMind.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func delete(_ id: UUID) throws {
        guard let dbQueue = dbQueue else { return }

        try dbQueue.write { db in
            _ = try FlashMind.deleteOne(db, key: id)
        }
    }

    func softDelete(_ id: UUID) throws {
        guard let dbQueue = dbQueue else { return }

        try dbQueue.write { db in
            if var flashMind = try FlashMind.fetchOne(db, key: id) {
                flashMind.deletedAt = Date()
                try flashMind.save(db)
            }
        }
    }

    func countByStatus(_ status: FlashMindStatus) throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }

        return try dbQueue.read { db in
            try FlashMind
                .filter(FlashMind.Columns.status == status.rawValue)
                .filter(FlashMind.Columns.deletedAt == nil)
                .fetchCount(db)
        }
    }
}
