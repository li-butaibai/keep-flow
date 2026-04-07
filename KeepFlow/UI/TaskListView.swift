import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                    TaskRow(
                        task: task,
                        isSelected: viewModel.interactionMode == .selection && index == viewModel.selectedIndex,
                        onStatusTap: {
                            viewModel.completeTask(at: index)
                        }
                    )
                        .onTapGesture {
                            viewModel.selectedIndex = index
                            viewModel.interactionMode = .selection
                        }

                    if index < viewModel.tasks.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.12))
                    }
                }

                if viewModel.hasMoreTasks {
                    Button(action: {
                        viewModel.loadMoreTasks()
                    }) {
                        Text(localization.localized("tasks.load_more"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.visible)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}
