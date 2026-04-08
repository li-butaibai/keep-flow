import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var flows: [Flow] = []
    @Published var selectedIndex: Int = 0
    @Published var shouldResetFocus: Bool = false
    @Published var visibleFlowLimit: Int = AppSettings.shared.flowListLimit
    @Published var totalVisibleFlowCount: Int = 0

    enum InteractionMode {
        case input
        case selection
    }
    @Published var interactionMode: InteractionMode = .input

    init() {
        fetchFlows()
    }

    func submit() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let result = FlowManager.shared.addFlow(content: content)
        switch result {
        case .success:
            inputText = ""
            fetchFlows()
        case .failure(let error):
            print("Failed to add flow: \(error)")
        }
    }

    func completeFlow(at index: Int) {
        guard index >= 0 && index < flows.count else { return }
        let flow = flows[index]

        do {
            try FlowManager.shared.completeFlow(id: flow.id)
            fetchFlows()
        } catch {
            print("Failed to complete flow: \(error)")
        }
    }

    func fetchFlows() {
        totalVisibleFlowCount = FlowManager.shared.visibleFlowCount()
        flows = FlowManager.shared.fetchFlows(limit: visibleFlowLimit)

        if flows.isEmpty {
            interactionMode = .input
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex, flows.count - 1)
        }

        DispatchQueue.main.async {
            if WindowManager.shared.isVisible {
                WindowManager.shared.resizePanelToContent()
            }
        }
    }

    func resetFlowPagination() {
        visibleFlowLimit = AppSettings.shared.flowListLimit
    }

    func loadMoreFlows() {
        guard hasMoreFlows else { return }
        visibleFlowLimit += Constants.Layout.flowListPageSize
        fetchFlows()
    }

    var hasMoreFlows: Bool {
        flows.count < totalVisibleFlowCount
    }

    func selectNext() {
        guard !flows.isEmpty else { return }
        if interactionMode == .input {
            interactionMode = .selection
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex + 1, flows.count - 1)
        }
    }

    func selectPrevious() {
        guard !flows.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
    }

    func confirmSelection() {
        guard interactionMode == .selection && selectedIndex < flows.count else { return }
        completeFlow(at: selectedIndex)
    }
}
