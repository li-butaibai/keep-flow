import Foundation
import GRDB

enum FlowStatus: String, Codable, DatabaseValueConvertible {
    case todo
    case done
}

struct Flow: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var status: FlowStatus
    var createdAt: Date
    var completedAt: Date?
    var deletedAt: Date?
    var flowType: String?

    init(
        id: UUID = UUID(),
        content: String,
        status: FlowStatus = .todo,
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

extension Flow: FetchableRecord, PersistableRecord {
    static let databaseTableName = "flows"

    enum Columns: String, ColumnExpression {
        case id, content, status, createdAt, completedAt, deletedAt, flowType
    }
}
