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

        migrator.registerMigration("v1_create_flashminds") { db in
            try db.create(table: "flashminds", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("content", .text).notNull()
                t.column("status", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("completedAt", .datetime)
                t.column("deletedAt", .datetime)
                t.column("flowType", .text)
            }
        }

        migrator.registerMigration("v2_migrate_flows_to_flashminds") { db in
            // Check if old "flows" table exists and has data
            let tableExists = try db.tableExists("flows")
            if tableExists {
                // Copy all data from flows to flashminds
                try db.execute(sql: """
                    INSERT OR IGNORE INTO flashminds (id, content, status, createdAt, completedAt, deletedAt, flowType)
                    SELECT id, content, status, createdAt, completedAt, deletedAt, flowType FROM flows
                """)
                // Drop the old table
                try db.drop(table: "flows")
            }
        }

        try migrator.migrate(dbQueue)
    }

    private func retryFallbackQueue() throws {
        guard let dbQueue = dbQueue else { return }

        let failedFlashMinds = fallbackQueue.drain()
        for flashMind in failedFlashMinds {
            do {
                try dbQueue.write { db in
                    try flashMind.save(db)
                }
            } catch {
                // Still failing, add back to queue for next retry
                fallbackQueue.enqueue(flashMind)
                print("Failed to retry flashMind \(flashMind.id): \(error)")
            }
        }
    }

    func addToFallbackQueue(_ flashMind: FlashMind) {
        fallbackQueue.enqueue(flashMind)
    }

    func fallbackQueueCount() -> Int {
        return fallbackQueue.count
    }
}

// MARK: - In-Memory Fallback Queue

final class InMemoryFallbackQueue {
    private var queue: [FlashMind] = []
    private let queueKey = "com.keepflow.failed_flashminds"

    init() {
        loadFromDisk()
    }

    func enqueue(_ flashMind: FlashMind) {
        queue.append(flashMind)
        saveToDisk()
    }

    func drain() -> [FlashMind] {
        let flashMinds = queue
        queue.removeAll()
        saveToDisk()
        return flashMinds
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
              let flashMinds = try? JSONDecoder().decode([FlashMind].self, from: data) else {
            return
        }
        queue = flashMinds
    }
}
