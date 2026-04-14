import Foundation

final class FlashMindManager {
    static let shared = FlashMindManager()

    private let repository: FlashMindRepository

    private init() {
        self.repository = FlashMindRepositoryImpl()
    }

    func addFlashMind(content: String) -> Result<FlashMind, Error> {
        let flashMind = FlashMind(content: content)
        do {
            try repository.save(flashMind)
            return .success(flashMind)
        } catch {
            return .failure(error)
        }
    }

    func completeFlashMind(id: UUID) throws {
        guard var flashMind = try repository.findById(id) else {
            throw FlashMindError.notFound
        }
        flashMind.status = .done
        flashMind.completedAt = Date()
        try repository.save(flashMind)
    }

    func updateFlashMind(id: UUID, content: String) throws {
        guard var flashMind = try repository.findById(id) else {
            throw FlashMindError.notFound
        }
        flashMind.content = content
        try repository.save(flashMind)
    }

    func undoComplete(id: UUID) throws {
        guard var flashMind = try repository.findById(id) else {
            throw FlashMindError.notFound
        }
        flashMind.status = .todo
        flashMind.completedAt = nil
        try repository.save(flashMind)
    }

    func deleteFlashMind(id: UUID) throws {
        try repository.softDelete(id)
    }

    func fetchFlashMinds(limit: Int = 5) -> [FlashMind] {
        do {
            return try repository.findAll(limit: limit)
        } catch {
            print("Failed to fetch flashMinds: \(error)")
            return []
        }
    }

    func visibleFlashMindCount() -> Int {
        do {
            return try repository.countAll()
        } catch {
            print("Failed to count all flashMinds: \(error)")
            return 0
        }
    }
}

enum FlashMindError: Error {
    case notFound
    case validationFailed(String)
}
