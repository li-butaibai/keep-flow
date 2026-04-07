import AppKit
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar icon
        setupStatusBar()

        // Register global shortcut (Shift+Space)
        ShortcutManager.shared.register()

        // Initialize database
        do {
            try DatabaseManager.shared.initialize()
        } catch {
            print("Database initialization failed: \(error)")
        }

        // Keep app running in background (no dock icon via LSUIElement)
        NSApp.setActivationPolicy(.accessory)
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "KeepFlow")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            // Left click - toggle window
            WindowManager.shared.toggle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "打开 KeepFlow", action: #selector(openKeepFlow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openKeepFlow() {
        WindowManager.shared.show()
    }

    @objc private func openSettings() {
        let settingsWindow = SettingsWindow()
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        ShortcutManager.shared.unregister()
    }
}

// MARK: - Settings Window

class SettingsWindow: NSWindow {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        self.title = "KeepFlow 设置"
        self.contentViewController = SettingsViewController()
        self.center()
        self.isReleasedWhenClosed = false
    }
}

class SettingsViewController: NSViewController {

    private var taskLimitField: NSTextField!
    private var shortcutRecordView: ShortcutRecordView!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // Task limit setting
        let taskLimitLabel = NSTextField(labelWithString: "默认显示任务数量:")
        taskLimitLabel.frame = NSRect(x: 20, y: 150, width: 140, height: 24)
        view.addSubview(taskLimitLabel)

        taskLimitField = NSTextField(frame: NSRect(x: 170, y: 150, width: 60, height: 24))
        taskLimitField.stringValue = "\(AppSettings.shared.taskListLimit)"
        taskLimitField.alignment = .center
        view.addSubview(taskLimitField)

        // Shortcut setting
        let shortcutLabel = NSTextField(labelWithString: "唤醒快捷键:")
        shortcutLabel.frame = NSRect(x: 20, y: 110, width: 140, height: 24)
        view.addSubview(shortcutLabel)

        shortcutRecordView = ShortcutRecordView(frame: NSRect(x: 170, y: 110, width: 180, height: 24))
        view.addSubview(shortcutRecordView)

        // Save button
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveSettings))
        saveButton.frame = NSRect(x: 150, y: 40, width: 100, height: 32)
        saveButton.bezelStyle = .rounded
        view.addSubview(saveButton)
    }

    @objc private func saveSettings() {
        if let limit = Int(taskLimitField.stringValue), limit > 0 && limit <= 20 {
            AppSettings.shared.taskListLimit = limit
        }

        AppSettings.shared.shortcutKeyCode = shortcutRecordView.keyCode
        AppSettings.shared.shortcutModifiers = shortcutRecordView.modifiers
        ShortcutManager.shared.updateShortcut(
            keyCode: shortcutRecordView.keyCode,
            modifiers: shortcutRecordView.modifiers
        )

        view.window?.close()
    }
}

// MARK: - Shortcut Record View

class ShortcutRecordView: NSView {
    var keyCode: UInt32 = 49
    var modifiers: UInt32 = UInt32(shiftKey)

    private var isRecording = false
    private var displayLabel: NSTextField!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        displayLabel = NSTextField(labelWithString: AppSettings.shared.shortcutDisplayString)
        displayLabel.frame = bounds
        displayLabel.alignment = .center
        displayLabel.isEditable = false
        displayLabel.isBordered = false
        addSubview(displayLabel)

        updateDisplay()
    }

    private func updateDisplay() {
        displayLabel.stringValue = AppSettings.shared.shortcutDisplayString
    }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        layer?.borderColor = NSColor.systemBlue.cgColor
        displayLabel.stringValue = "按下快捷键..."
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        keyCode = UInt32(event.keyCode)
        modifiers = UInt32(event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue)

        isRecording = false
        layer?.borderColor = NSColor.separatorColor.cgColor
        updateDisplay()
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            isRecording = false
            layer?.borderColor = NSColor.separatorColor.cgColor
            updateDisplay()
        }
        return super.resignFirstResponder()
    }
}

// MARK: - App Settings

class AppSettings {
    static let shared = AppSettings()

    private let taskLimitKey = "com.keepflow.taskListLimit"
    private let shortcutKeyCodeKey = "com.keepflow.shortcutKeyCode"
    private let shortcutModifiersKey = "com.keepflow.shortcutModifiers"

    private init() {}

    var taskListLimit: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: taskLimitKey)
            return value > 0 ? value : 5
        }
        set {
            UserDefaults.standard.set(newValue, forKey: taskLimitKey)
        }
    }

    var shortcutKeyCode: UInt32 {
        get {
            let value = UserDefaults.standard.integer(forKey: shortcutKeyCodeKey)
            return value > 0 ? UInt32(value) : 49
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: shortcutKeyCodeKey)
        }
    }

    var shortcutModifiers: UInt32 {
        get {
            let value = UserDefaults.standard.integer(forKey: shortcutModifiersKey)
            return value > 0 ? UInt32(value) : UInt32(shiftKey)
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: shortcutModifiersKey)
        }
    }

    var shortcutDisplayString: String {
        var parts: [String] = []
        let mods = self.shortcutModifiers
        if mods & UInt32(controlKey) != 0 { parts.append("^") }
        if mods & UInt32(optionKey) != 0 { parts.append("Option") }
        if mods & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if mods & UInt32(cmdKey) != 0 { parts.append("Cmd") }

        let keyString = keyCodeToString(self.shortcutKeyCode)
        parts.append(keyString)

        return parts.joined(separator: "+")
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 53: return "Esc"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key\(keyCode)"
        }
    }
}
