import SwiftUI
import AppKit

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.Window.cornerRadius, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.96))

            VStack(spacing: Constants.Layout.contentSpacing) {
                InputView(viewModel: viewModel)
                    .frame(height: Constants.Layout.inputFieldHeight)

                if viewModel.flashMinds.count > 0 {
                    Divider()
                        .background(Color.gray.opacity(0.35))

                    HStack {
                        Text(localization.localized("app.slogan"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.85))
                            .tracking(0.2)

                        Spacer()
                    }
                }

                flashMindListContainer
                    .frame(maxHeight: Constants.Layout.flashMindListMaxHeight)
            }
            .padding(Constants.Layout.contentPadding)
        }
        .frame(width: Constants.Window.width)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Window.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var flashMindListContainer: some View {
        if viewModel.flashMinds.count > 0 {
            FlashMindListView(viewModel: viewModel)
        } else {
            EmptyView()
        }
    }
}
