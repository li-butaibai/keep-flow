import Foundation
import GRDB

enum FlashMindStatus: String, Codable, DatabaseValueConvertible {
    case todo
    case done
}

struct FlashMind: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var status: FlashMindStatus
    var createdAt: Date
    var completedAt: Date?
    var deletedAt: Date?
    var flowType: String?

    init(
        id: UUID = UUID(),
        content: String,
        status: FlashMindStatus = .todo,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        flowType: String? = nil
    ) {
        self.id = id
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.flowType = flowType
    }
}

// MARK: - GRDB Conformance

extension FlashMind: FetchableRecord, PersistableRecord {
    static let databaseTableName = "flashminds"

    enum Columns: String, ColumnExpression {
        case id, content, status, createdAt, completedAt, deletedAt, flowType
    }
}
