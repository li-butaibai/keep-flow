import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var tasks: [Task] = []
    @Published var selectedIndex: Int = 0
    @Published var shouldResetFocus: Bool = false
    @Published var visibleTaskLimit: Int = AppSettings.shared.taskListLimit
    @Published var totalVisibleTaskCount: Int = 0

    enum InteractionMode {
        case input
        case selection
    }
    @Published var interactionMode: InteractionMode = .input

    init() {
        fetchTasks()
    }

    func submit() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let result = TaskManager.shared.addTask(content: content)
        switch result {
        case .success:
            inputText = ""
            fetchTasks()
        case .failure(let error):
            print("Failed to add task: \(error)")
        }
    }

    func completeTask(at index: Int) {
        guard index >= 0 && index < tasks.count else { return }
        let task = tasks[index]

        do {
            try TaskManager.shared.completeTask(id: task.id)
            fetchTasks()
        } catch {
            print("Failed to complete task: \(error)")
        }
    }

    func fetchTasks() {
        totalVisibleTaskCount = TaskManager.shared.visibleTaskCount()
        tasks = TaskManager.shared.fetchTasks(limit: visibleTaskLimit)

        if tasks.isEmpty {
            interactionMode = .input
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex, tasks.count - 1)
        }

        DispatchQueue.main.async {
            if WindowManager.shared.isVisible {
                WindowManager.shared.resizePanelToContent()
            }
        }
    }

    func resetTaskPagination() {
        visibleTaskLimit = AppSettings.shared.taskListLimit
    }

    func loadMoreTasks() {
        guard hasMoreTasks else { return }
        visibleTaskLimit += Constants.Layout.taskListPageSize
        fetchTasks()
    }

    var hasMoreTasks: Bool {
        tasks.count < totalVisibleTaskCount
    }

    func selectNext() {
        guard !tasks.isEmpty else { return }
        if interactionMode == .input {
            interactionMode = .selection
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex + 1, tasks.count - 1)
        }
    }

    func selectPrevious() {
        guard !tasks.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
    }

    func confirmSelection() {
        guard interactionMode == .selection && selectedIndex < tasks.count else { return }
        completeTask(at: selectedIndex)
    }
}
