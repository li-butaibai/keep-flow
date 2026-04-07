import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case italian = "it"

    var localizationCode: String? {
        switch self {
        case .system:
            return nil
        default:
            return rawValue
        }
    }

    var displayNameKey: String {
        switch self {
        case .system: return "language.system"
        case .english: return "language.english"
        case .simplifiedChinese: return "language.simplified_chinese"
        case .traditionalChinese: return "language.traditional_chinese"
        case .japanese: return "language.japanese"
        case .korean: return "language.korean"
        case .french: return "language.french"
        case .german: return "language.german"
        case .italian: return "language.italian"
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("com.keepflow.languageDidChange")
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private let languageKey = "com.keepflow.appLanguage"

    @Published private(set) var selectedLanguage: AppLanguage

    private init() {
        let storedValue = UserDefaults.standard.string(forKey: languageKey)
        self.selectedLanguage = AppLanguage(rawValue: storedValue ?? "") ?? .system
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        objectWillChange.send()
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    func displayName(for language: AppLanguage) -> String {
        localized(language.displayNameKey)
    }

    private var bundle: Bundle {
        if let code = selectedLanguage.localizationCode,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        for preferred in Bundle.main.preferredLocalizations {
            if let path = Bundle.main.path(forResource: preferred, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }

            let normalized = preferred.replacingOccurrences(of: "_", with: "-")
            if let path = Bundle.main.path(forResource: normalized, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }

            if let languageCode = Locale(identifier: preferred).language.languageCode?.identifier,
               let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }

        return Bundle.main
    }
}

enum L10n {
    static func tr(_ key: String) -> String {
        LocalizationManager.shared.localized(key)
    }
}
