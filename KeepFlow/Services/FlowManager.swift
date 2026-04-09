import Foundation

final class FlowManager {
    static let shared = FlowManager()

    private let repository: FlowRepository

    private init() {
        self.repository = FlowRepositoryImpl()
    }

    func addFlow(content: String) -> Result<Flow, Error> {
        let flow = Flow(content: content)
        do {
            try repository.save(flow)
            return .success(flow)
        } catch {
            return .failure(error)
        }
    }

    func completeFlow(id: UUID) throws {
        guard var flow = try repository.findById(id) else {
            throw FlowError.notFound
        }
        flow.status = .done
        flow.completedAt = Date()
        try repository.save(flow)
    }

    func updateFlow(id: UUID, content: String) throws {
        guard var flow = try repository.findById(id) else {
            throw FlowError.notFound
        }
        flow.content = content
        try repository.save(flow)
    }

    func undoComplete(id: UUID) throws {
        guard var flow = try repository.findById(id) else {
            throw FlowError.notFound
        }
        flow.status = .todo
        flow.completedAt = nil
        try repository.save(flow)
    }

    func deleteFlow(id: UUID) throws {
        try repository.softDelete(id)
    }

    func fetchFlows(limit: Int = 5) -> [Flow] {
        do {
            return try repository.findAll(limit: limit)
        } catch {
            print("Failed to fetch flows: \(error)")
            return []
        }
    }

    func visibleFlowCount() -> Int {
        do {
            return try repository.countAll()
        } catch {
            print("Failed to count all flows: \(error)")
            return 0
        }
    }
}

enum FlowError: Error {
    case notFound
    case validationFailed(String)
}
