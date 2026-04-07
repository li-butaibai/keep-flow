import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var tasks: [Task] = []
    @Published var selectedIndex: Int = 0
    @Published var shouldResetFocus: Bool = false

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
            WindowManager.shared.close()
        } catch {
            print("Failed to complete task: \(error)")
        }
    }

    func fetchTasks() {
        tasks = TaskManager.shared.fetchTasks(limit: AppSettings.shared.taskListLimit)
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
