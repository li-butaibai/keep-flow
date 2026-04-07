import AppKit
import SwiftUI

class WindowManager {
    static let shared = WindowManager()

    private var _panel: NSPanel?
    private let panelDelegate = PanelDelegate()
    private(set) var mainViewModel: MainViewModel?

    private init() {}

    var panel: NSPanel {
        if _panel == nil {
            _panel = createPanel()
        }
        return _panel!
    }

    var isVisible: Bool {
        panel.isVisible
    }

    private func createPanel() -> NSPanel {
        let contentRect = NSRect(
            x: 0,
            y: 0,
            width: Constants.Window.width,
            height: Constants.Window.height
        )

        let panel = KeepFlowPanel(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Floating panel behavior
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        // Visual configuration
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        // Content view with blur effect
        let visualEffect = NSVisualEffectView(frame: panel.contentView!.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = Constants.Window.cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]

        // Embed SwiftUI view
        mainViewModel = MainViewModel()
        let hostingView = NSHostingView(rootView: MainView(viewModel: mainViewModel!))
        hostingView.frame = visualEffect.bounds
        hostingView.autoresizingMask = [.width, .height]

        visualEffect.addSubview(hostingView)
        panel.contentView = visualEffect

        // Center on screen
        panel.setFrameOrigin(centeredOrigin(for: panel))

        panel.delegate = panelDelegate

        return panel
    }

    private func centeredOrigin(for panel: NSPanel) -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint.zero
        }
        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let x = screenFrame.origin.x + (screenFrame.width - panelFrame.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - panelFrame.height) / 2
        return NSPoint(x: x, y: y)
    }

    func show() {
        panel.setFrameOrigin(centeredOrigin(for: panel))

        // Reset view model state when showing
        mainViewModel?.inputText = ""
        mainViewModel?.interactionMode = .input
        mainViewModel?.selectedIndex = 0
        mainViewModel?.fetchTasks()
        mainViewModel?.shouldResetFocus = true

        // Fade in animation
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Constants.Animation.fadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        // Bring to front and activate
        panel.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        // Fade out animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.Animation.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
        })
    }

    func toggle() {
        if isVisible {
            close()
        } else {
            show()
        }
    }

    func close() {
        hide()
    }
}

// MARK: - KeepFlowPanel

class KeepFlowPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        // ESC key - close immediately
        WindowManager.shared.close()
    }

    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Shift+Enter to close (without saving)
        if keyCode == 36 && modifiers.contains(.shift) {
            WindowManager.shared.close()
            return
        }

        // Let the first responder handle arrow keys and Enter
        if let firstResponder = self.firstResponder {
            if let view = firstResponder as? NSView, view.window == self {
                // Check if it's our KeyboardInterceptingView or a SwiftUI view
                if String(describing: type(of: view)).contains("Keyboard") ||
                   String(describing: type(of: view)).contains("TextField") {
                    // Let it handle
                    super.keyDown(with: event)
                    return
                }
            }
        }

        // Handle arrow keys at window level
        if keyCode == 125 { // Down arrow
            WindowManager.shared.mainViewModel?.selectNext()
            return
        }
        if keyCode == 126 { // Up arrow
            WindowManager.shared.mainViewModel?.selectPrevious()
            return
        }

        super.keyDown(with: event)
    }
}

// MARK: - PanelDelegate

class PanelDelegate: NSObject, NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        // Delay to allow clicking on panel content without closing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let panel = notification.object as? NSPanel else { return }
            if !panel.isKeyWindow && WindowManager.shared.isVisible {
                WindowManager.shared.close()
            }
        }
    }
}
