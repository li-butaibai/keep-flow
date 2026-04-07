import Foundation

enum Constants {
    enum Window {
        static let width: CGFloat = 680
        static let height: CGFloat = 500
        static let cornerRadius: CGFloat = 14
    }

    enum Animation {
        static let fadeInDuration: TimeInterval = 0.15
        static let fadeOutDuration: TimeInterval = 0.10
        static let listItemDuration: TimeInterval = 0.10
    }

    enum Layout {
        static let taskListLimit: Int = 5
        static let inputFieldHeight: CGFloat = 44
    }

    enum Database {
        static let fileName = "keepflow.sqlite"
        static let directoryName = "KeepFlow"
    }
}
