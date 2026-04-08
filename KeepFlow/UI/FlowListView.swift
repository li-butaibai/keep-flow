import SwiftUI

struct FlowListView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.flows.enumerated()), id: \.element.id) { index, flow in
                    FlowRow(
                        flow: flow,
                        isSelected: viewModel.interactionMode == .selection && index == viewModel.selectedIndex,
                        onStatusTap: {
                            viewModel.completeFlow(at: index)
                        }
                    )
                        .onTapGesture {
                            viewModel.selectedIndex = index
                            viewModel.interactionMode = .selection
                        }

                    if index < viewModel.flows.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.12))
                    }
                }

                if viewModel.hasMoreFlows {
                    Button(action: {
                        viewModel.loadMoreFlows()
                    }) {
                        Text(localization.localized("flows.load_more"))
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
