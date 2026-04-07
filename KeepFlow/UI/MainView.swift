import SwiftUI
import AppKit

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    private var dynamicHeight: CGFloat {
        let inputHeight: CGFloat = 44
        let taskRowHeight: CGFloat = 36
        let maxTasks = AppSettings.shared.taskListLimit
        let taskCount = min(viewModel.tasks.count, maxTasks)
        let taskListHeight = taskCount > 0 ? CGFloat(taskCount) * taskRowHeight : 0
        let emptyHeight: CGFloat = taskCount == 0 ? 40 : 0

        return inputHeight + taskListHeight + emptyHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            InputView(viewModel: viewModel)
                .padding(.top, 0)

            if viewModel.tasks.count > 0 {
                TaskListView(viewModel: viewModel)
            }
        }
        .frame(width: Constants.Window.width, height: dynamicHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
    }
}
