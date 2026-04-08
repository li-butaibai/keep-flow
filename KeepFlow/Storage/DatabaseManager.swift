import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue?
    private let fallbackQueue: InMemoryFallbackQueue

    private init() {
        self.fallbackQueue = InMemoryFallbackQueue()
    }

    var database: DatabaseQueue? {
        return dbQueue
    }

    func initialize() throws {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let keepFlowDir = appSupportURL.appendingPathComponent("KeepFlow", isDirectory: true)

        // Create directory if needed
        if !fileManager.fileExists(atPath: keepFlowDir.path) {
            try fileManager.createDirectory(at: keepFlowDir, withIntermediateDirectories: true)
        }

        let dbPath = keepFlowDir.appendingPathComponent("keepflow.sqlite").path

        // Setup database with migrations
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { print("SQL: \($0)") }
        }

        dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

        // Run migrations
        try migrate()

        // Retry any failed writes from previous sessions
        try retryFallbackQueue()
    }

    private func migrate() throws {
        guard let dbQueue = dbQueue else { return }

        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_flows") { db in
            try db.create(table: "flows", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("content", .text).notNull()
                t.column("status", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("completedAt", .datetime)
                t.column("deletedAt", .datetime)
                t.column("flowType", .text)
            }
        }

        try migrator.migrate(dbQueue)
    }

    private func retryFallbackQueue() throws {
        guard let dbQueue = dbQueue else { return }

        let failedFlows = fallbackQueue.drain()
        for flow in failedFlows {
            do {
                try dbQueue.write { db in
                    try flow.save(db)
                }
            } catch {
                // Still failing, add back to queue for next retry
                fallbackQueue.enqueue(flow)
                print("Failed to retry flow \(flow.id): \(error)")
            }
        }
    }

    func addToFallbackQueue(_ flow: Flow) {
        fallbackQueue.enqueue(flow)
    }

    func fallbackQueueCount() -> Int {
        return fallbackQueue.count
    }
}

// MARK: - In-Memory Fallback Queue

final class InMemoryFallbackQueue {
    private var queue: [Flow] = []
    private let queueKey = "com.keepflow.failed_flows"

    init() {
        loadFromDisk()
    }

    func enqueue(_ flow: Flow) {
        queue.append(flow)
        saveToDisk()
    }

    func drain() -> [Flow] {
        let flows = queue
        queue.removeAll()
        saveToDisk()
        return flows
    }

    var count: Int {
        return queue.count
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: queueKey)
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let flows = try? JSONDecoder().decode([Flow].self, from: data) else {
            return
        }
        queue = flows
    }
}
