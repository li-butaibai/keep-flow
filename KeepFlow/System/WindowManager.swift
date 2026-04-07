import AppKit
import SwiftUI

class WindowManager {
    static let shared = WindowManager()

    private var _panel: NSPanel?
    private let panelDelegate = PanelDelegate()
    private var localKeyMonitor: Any?
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
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
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
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor)
        ])
        panel.contentView = visualEffect

        // Position similar to launcher UIs such as Raycast: centered horizontally,
        // anchored near the top of the visible screen area.
        panel.setFrameOrigin(topCenteredOrigin(for: panel))

        panel.delegate = panelDelegate

        return panel
    }

    private func topCenteredOrigin(for panel: NSPanel) -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint.zero
        }
        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let x = screenFrame.origin.x + (screenFrame.width - panelFrame.width) / 2
        let y = screenFrame.maxY - Constants.Window.topOffset - panelFrame.height
        return NSPoint(x: x, y: y)
    }

    func show() {
        // Reset view model state when showing
        mainViewModel?.inputText = ""
        mainViewModel?.interactionMode = .input
        mainViewModel?.selectedIndex = 0
        mainViewModel?.resetTaskPagination()
        mainViewModel?.fetchTasks()
        mainViewModel?.shouldResetFocus = true

        // Resize panel based on content
        resizePanelToContent()
        installKeyMonitorIfNeeded()

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

    func resizePanelToContent() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        guard let visualEffect = panel.contentView else { return }

        // Get the hosting view
        guard let hostingView = visualEffect.subviews.first(where: { $0 is NSHostingView<MainView> }) as? NSHostingView<MainView> else {
            return
        }

        // Calculate height: InputView (44) + TaskListView (0 or auto)
        let inputHeight: CGFloat = Constants.Layout.inputFieldHeight
        // Reset hostingView to calculate true content size
        hostingView.frame.size = NSSize(width: Constants.Window.width, height: 0)
        let contentSize = hostingView.fittingSize

        // Always respect the SwiftUI content's fitted height.
        // The panel has title/content chrome, so forcing a 44pt window clips the input field.
        let newHeight = min(
            max(contentSize.height, inputHeight),
            Constants.Layout.panelMaxHeight
        )

        let newWidth = Constants.Window.width
        let newFrame = NSRect(
            x: screenFrame.origin.x + (screenFrame.width - newWidth) / 2,
            y: screenFrame.maxY - Constants.Window.topOffset - newHeight,
            width: newWidth,
            height: newHeight
        )

        // Resize panel
        panel.setFrame(newFrame, display: true, animate: false)
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
        removeKeyMonitor()
        hide()
    }

    private func installKeyMonitorIfNeeded() {
        guard localKeyMonitor == nil else { return }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.panel.isVisible, self.panel.isKeyWindow else { return event }

            if self.handleKeyEvent(event) {
                return nil
            }

            return event
        }
    }

    private func removeKeyMonitor() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }

    fileprivate func handleKeyEvent(_ event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if keyCode == 36 && modifiers.contains(.shift) {
            close()
            return true
        }

        if keyCode == 125 { // Down arrow
            mainViewModel?.selectNext()
            return true
        }

        if keyCode == 126 { // Up arrow
            mainViewModel?.selectPrevious()
            return true
        }

        if keyCode == 48, mainViewModel?.interactionMode == .selection { // Tab
            mainViewModel?.confirmSelection()
            return true
        }

        return false
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
        if WindowManager.shared.handleKeyEvent(event) {
            return
        }

        // Let the first responder handle text input and submit.
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
