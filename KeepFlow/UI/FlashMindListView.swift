import SwiftUI

struct FlashMindListView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.flashMinds.enumerated()), id: \.element.id) { index, flashMind in
                    FlashMindRow(
                        flashMind: flashMind,
                        isSelected: viewModel.interactionMode == .selection && index == viewModel.selectedIndex,
                        onStatusTap: {
                            viewModel.completeFlashMind(at: index)
                        }
                    )
                        .onTapGesture {
                            viewModel.selectedIndex = index
                            viewModel.interactionMode = .selection
                        }

                    if index < viewModel.flashMinds.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.12))
                    }
                }

                if viewModel.hasMoreFlashMinds {
                    Button(action: {
                        viewModel.loadMoreFlashMinds()
                    }) {
                        Text(localization.localized("flashminds.load_more"))
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
