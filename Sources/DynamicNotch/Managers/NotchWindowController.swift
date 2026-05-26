import Cocoa
import SwiftUI

/// 灵动岛窗口控制器
/// DragOverlayView 作为窗口 contentView（处理文件拖拽），SwiftUI NSHostingView 作为子视图嵌在其中
final class NotchWindowController: NSObject {
    var window: NotchWindow?
    var vm: NotchViewModel?
    weak var screen: NSScreen?

    override init() {
        super.init()
        setup()
    }

    deinit { destroy() }

    private func setup() {
        logDiag("setup() start, windowHeight=\(NotchViewModel.windowHeight)")
        let allScreens = NSScreen.screens
        logDiag("screens count: \(allScreens.count)")
        for (i, s) in allScreens.enumerated() {
            logDiag("  screen \(i): frame=\(NSStringFromRect(s.frame)) visible=\(NSStringFromRect(s.visibleFrame))")
        }
        guard let screen = NSScreen.main ?? allScreens.first else {
            logDiag("ERROR: no screen!")
            return
        }
        self.screen = screen
        logDiag("using screen: \(NSStringFromRect(screen.frame))")

        let wh = NotchViewModel.windowHeight
        let wFrame = CGRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y + screen.frame.height - wh,
            width: screen.frame.width,
            height: wh
        )

        let window = NotchWindow(
            contentRect: wFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        self.window = window

        let vm = NotchViewModel.shared
        self.vm = vm
        vm.screenRect = screen.frame
        vm.recomputeAdaptiveSizes(for: screen)

        // DragOverlayView 作为窗口 contentView（处理文件拖拽 → AirDrop）
        // SwiftUI 内容作为其子视图，hitTest 自然穿透到最深处
        let dragView = DragOverlayView(vm: vm)
        window.contentView = dragView

        let hostingView = NSHostingView(rootView: NotchView(vm: vm))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        dragView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: dragView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: dragView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: dragView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: dragView.bottomAnchor),
        ])

        window.setFrameOrigin(wFrame.origin)
        window.setContentSize(wFrame.size)
        window.makeKeyAndOrderFront(nil)
        logDiag("window frame=\(NSStringFromRect(window.frame)), isVisible=\(window.isVisible), isKey=\(window.isKeyWindow)")

        // 启动全局事件监听（核心：鼠标 hover/click 检测）
        vm.setupEvents()

        // 屏幕变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenDidChange() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        self.screen = screen
        vm?.screenRect = screen.frame
        vm?.recomputeAdaptiveSizes(for: screen)

        let wh = NotchViewModel.windowHeight
        let wFrame = CGRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y + screen.frame.height - wh,
            width: screen.frame.width,
            height: wh
        )
        window?.setFrameOrigin(wFrame.origin)
        window?.setContentSize(wFrame.size)
    }

    func destroy() {
        vm?.destroy()
        window?.close()
        window = nil
        vm = nil
    }
}

// MARK: - 拖拽处理视图（窗口 contentView，内嵌 SwiftUI）

fileprivate class DragOverlayView: NSView {
    weak var vm: NotchViewModel?

    init(vm: NotchViewModel) {
        self.vm = vm
        super.init(frame: .zero)
        registerForDraggedTypes([.fileURL, .URL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 不覆盖 hitTest — SwiftUI 子视图（NSHostingView）充满整个区域，
    // hitTest 自动返回最深子视图。鼠标事件 → SwiftUI 内容；拖拽事件 → 本视图

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        vm?.handleDragEntered(at: NSEvent.mouseLocation)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        vm?.handleDragEntered(at: NSEvent.mouseLocation)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        vm?.handleDragExited()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self], options: nil) as? [URL] ?? []
        guard !urls.isEmpty else { return false }
        vm?.handleDrop(urls: urls)
        return true
    }
}

// MARK: - 文件诊断日志（print() 在 GUI app 中不输出）

private func logDiag(_ msg: String) {
    let line = "\(Date().timeIntervalSince1970) [NotchWC] \(msg)\n"
    if let data = line.data(using: .utf8) {
        let path = "/tmp/notch_wc.log"
        if let fh = try? FileHandle(forWritingTo: URL(fileURLWithPath: path)) {
            _ = try? fh.seekToEnd()
            _ = try? fh.write(data)
            try? fh.close()
        } else {
            try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
    }
}