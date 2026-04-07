import Foundation
import GRDB

enum TaskStatus: String, Codable, DatabaseValueConvertible {
    case todo
    case done
}

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var status: TaskStatus
    var createdAt: Date
    var completedAt: Date?
    var deletedAt: Date?
    var taskType: String?

    init(
        id: UUID = UUID(),
        content: String,
        status: TaskStatus = .todo,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        taskType: String? = nil
    ) {
        self.id = id
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.taskType = taskType
    }
}

// MARK: - GRDB Conformance

extension Task: FetchableRecord, PersistableRecord {
    static let databaseTableName = "tasks"

    enum Columns: String, ColumnExpression {
        case id, content, status, createdAt, completedAt, deletedAt, taskType
    }
}
