import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.tasks.prefix(AppSettings.shared.taskListLimit).enumerated()), id: \.element.id) { index, task in
                TaskRow(task: task, isSelected: viewModel.interactionMode == .selection && index == viewModel.selectedIndex)
                    .onTapGesture {
                        viewModel.selectedIndex = index
                        viewModel.interactionMode = .selection
                    }

                if index < min(viewModel.tasks.count, AppSettings.shared.taskListLimit) - 1 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
