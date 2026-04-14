import SwiftUI

struct FlashMindRow: View {
    let flashMind: FlashMind
    var isSelected: Bool = false
    var onStatusTap: (() -> Void)? = nil

    @State private var appeared = false
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onStatusTap?()
            }) {
                ZStack {
                    Circle()
                        .fill(flashMind.status == .done ? Color.clear : Color.gray.opacity(0.2))
                        .frame(width: 14, height: 14)
                    if flashMind.status == .done {
                        Circle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: 14, height: 14)
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            // Content
            Text(flashMind.content)
                .font(.system(size: 13))
                .foregroundColor(flashMind.status == .done ? .gray : .black)
                .strikethrough(flashMind.status == .done)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            // Creation time
            Text(formattedTime)
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.5))

            // Status indicator
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.25) : Color.clear)
        )
        .contentShape(Rectangle())
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .animation(.easeInOut(duration: Constants.Animation.listItemDuration), value: appeared)
        .onAppear {
            appeared = true
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(flashMind.createdAt) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(flashMind.createdAt) {
            return localization.localized("date.yesterday")
        } else {
            formatter.dateFormat = "MM/dd"
        }

        return formatter.string(from: flashMind.createdAt)
    }
}
