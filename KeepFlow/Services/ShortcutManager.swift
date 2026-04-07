import AppKit
import Carbon

// MARK: - Shortcut Configuration

struct ShortcutConfiguration: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let `default` = ShortcutConfiguration(
        keyCode: 49,  // Space
        modifiers: UInt32(shiftKey)  // Shift+Space
    )

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append(L10n.tr("shortcut.modifier.control")) }
        if modifiers & UInt32(optionKey) != 0 { parts.append(L10n.tr("shortcut.modifier.option")) }
        if modifiers & UInt32(shiftKey) != 0 { parts.append(L10n.tr("shortcut.modifier.shift")) }
        if modifiers & UInt32(cmdKey) != 0 { parts.append(L10n.tr("shortcut.modifier.command")) }

        let keyString = keyCodeToString(keyCode)
        parts.append(keyString)

        return parts.joined(separator: "+")
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case 49: return L10n.tr("shortcut.key.space")
        case 36: return L10n.tr("shortcut.key.return")
        case 48: return L10n.tr("shortcut.key.tab")
        case 51: return L10n.tr("shortcut.key.delete")
        case 53: return L10n.tr("shortcut.key.escape")
        case 123: return L10n.tr("shortcut.key.left")
        case 124: return L10n.tr("shortcut.key.right")
        case 125: return L10n.tr("shortcut.key.down")
        case 126: return L10n.tr("shortcut.key.up")
        default: return "\(L10n.tr("shortcut.key.prefix"))\(keyCode)"
        }
    }
}

// MARK: - ShortcutManager

class ShortcutManager {
    static let shared = ShortcutManager()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    private let shortcutKey = "com.keepflow.shortcut"

    private init() {}

    var currentShortcut: ShortcutConfiguration {
        get {
            guard let data = UserDefaults.standard.data(forKey: shortcutKey),
                  let config = try? JSONDecoder().decode(ShortcutConfiguration.self, from: data) else {
                return .default
            }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: shortcutKey)
            }
        }
    }

    func register() {
        // Unregister existing first
        unregister()

        let config = currentShortcut

        // Register global hotkey
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerBlock: EventHandlerUPP = { _, event, _ -> OSStatus in

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if status == noErr && hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    WindowManager.shared.toggle()
                }
            }

            return noErr
        }

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        guard status == noErr else {
            print("Failed to install event handler: \(status)")
            return
        }

        // Register hotkey with current configuration
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B4657), id: 1) // "KF" signature

        let registerStatus = RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            print("Failed to register hot key: \(registerStatus)")
        }
    }

    func updateShortcut(keyCode: UInt32, modifiers: UInt32) {
        currentShortcut = ShortcutConfiguration(keyCode: keyCode, modifiers: modifiers)
        register()
    }

    func resetToDefault() {
        currentShortcut = .default
        register()
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}
