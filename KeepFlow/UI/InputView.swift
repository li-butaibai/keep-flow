import SwiftUI
import AppKit

struct InputView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var localization = LocalizationManager.shared
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 18, height: 18)
            }

            TextField(localization.localized("input.placeholder"), text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .focused($isFocused)
                .onSubmit {
                    submitIfValid()
                }

            if !viewModel.inputText.isEmpty {
                Button(action: clearInput) {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(.gray)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: Constants.Layout.inputFieldHeight)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            isFocused = true
        }
        .onChange(of: viewModel.shouldResetFocus) { newValue in
            if newValue {
                isFocused = true
                viewModel.shouldResetFocus = false
            }
        }
    }

    private func submitIfValid() {
        let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        viewModel.submit()
        WindowManager.shared.close()
    }

    private func clearInput() {
        viewModel.inputText = ""
    }
}
