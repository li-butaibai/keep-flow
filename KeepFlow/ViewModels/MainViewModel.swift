import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var flashMinds: [FlashMind] = []
    @Published var selectedIndex: Int = 0
    @Published var shouldResetFocus: Bool = false
    @Published var visibleFlashMindLimit: Int = AppSettings.shared.flashMindListLimit
    @Published var totalVisibleFlashMindCount: Int = 0

    enum InteractionMode {
        case input
        case selection
    }
    @Published var interactionMode: InteractionMode = .input
    @Published var editingFlashMindId: UUID? = nil

    init() {
        fetchFlashMinds()
    }

    func submit() {
        if editingFlashMindId != nil {
            saveEditedFlashMind()
            return
        }
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let result = FlashMindManager.shared.addFlashMind(content: content)
        switch result {
        case .success:
            inputText = ""
            fetchFlashMinds()
        case .failure(let error):
            print("Failed to add flashMind: \(error)")
        }
    }

    func completeFlashMind(at index: Int) {
        guard index >= 0 && index < flashMinds.count else { return }
        let flashMind = flashMinds[index]

        do {
            try FlashMindManager.shared.completeFlashMind(id: flashMind.id)
            fetchFlashMinds()
        } catch {
            print("Failed to complete flashMind: \(error)")
        }
    }

    func fetchFlashMinds() {
        totalVisibleFlashMindCount = FlashMindManager.shared.visibleFlashMindCount()
        flashMinds = FlashMindManager.shared.fetchFlashMinds(limit: visibleFlashMindLimit)

        if flashMinds.isEmpty {
            interactionMode = .input
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex, flashMinds.count - 1)
        }

        DispatchQueue.main.async {
            if WindowManager.shared.isVisible {
                WindowManager.shared.resizePanelToContent()
            }
        }
    }

    func resetFlashMindPagination() {
        visibleFlashMindLimit = AppSettings.shared.flashMindListLimit
    }

    func loadMoreFlashMinds() {
        guard hasMoreFlashMinds else { return }
        visibleFlashMindLimit += Constants.Layout.flashMindListPageSize
        fetchFlashMinds()
    }

    var hasMoreFlashMinds: Bool {
        flashMinds.count < totalVisibleFlashMindCount
    }

    func selectNext() {
        guard !flashMinds.isEmpty else { return }
        if interactionMode == .input {
            interactionMode = .selection
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex + 1, flashMinds.count - 1)
        }
    }

    func selectPrevious() {
        guard !flashMinds.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
    }

    func confirmSelection() {
        guard interactionMode == .selection && selectedIndex < flashMinds.count else { return }
        completeFlashMind(at: selectedIndex)
    }

    func loadFlashMindForEditing() {
        guard interactionMode == .selection && selectedIndex < flashMinds.count else { return }
        let flashMind = flashMinds[selectedIndex]
        editingFlashMindId = flashMind.id
        inputText = flashMind.content
        interactionMode = .input
        shouldResetFocus = true
    }

    func cancelEditing() {
        editingFlashMindId = nil
        inputText = ""
    }

    func saveEditedFlashMind() {
        guard let editingId = editingFlashMindId else { return }
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        do {
            try FlashMindManager.shared.updateFlashMind(id: editingId, content: content)
            editingFlashMindId = nil
            inputText = ""
            fetchFlashMinds()
            WindowManager.shared.close()
        } catch {
            print("Failed to update flashMind: \(error)")
        }
    }
}
