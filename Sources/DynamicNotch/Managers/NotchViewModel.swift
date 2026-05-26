import Cocoa
import SwiftUI

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

/// 灵动岛视图状态管理
/// 核心交互逻辑：全局事件监听捕获鼠标位置和点击 → 坐标判断决定开/关
/// 参考 NotchDrop 架构，不使用 NSTrackingArea / SwiftUI onTapGesture
final class NotchViewModel: NSObject, ObservableObject {
    static let shared = NotchViewModel()

    enum Status: Equatable {
        case closed
        case opened
    }

    override init() {
        let ud = UserDefaults.standard
        if ud.object(forKey: "collapsedHeight") != nil {
            let h = CGFloat(ud.double(forKey: "collapsedHeight"))
            collapsedHeight = h
            notchClosedSize.height = h
            hasCustomizedHeight = true
        }
        if ud.object(forKey: "autoCloseSeconds") != nil {
            autoCloseSeconds = ud.double(forKey: "autoCloseSeconds")
        }
        if ud.object(forKey: "mirrorEnabled") != nil {
            mirrorEnabled = ud.bool(forKey: "mirrorEnabled")
        }
        if let ids = ud.object(forKey: "selectedCalendarIDs") as? [String] {
            selectedCalendarIDs = Set(ids)
        }

        // 启动时清理过期缓存
        DispatchQueue.global(qos: .background).async {
            Self.cleanupStaleCaches()
        }
    }

    // MARK: - 尺寸

    let spacing: CGFloat = 16
    let cornerRadius: CGFloat = 22
    let inset: CGFloat = -4  // 点击扩大范围（负值扩大命中区）

    private var hasCustomizedHeight = false

    @Published var collapsedHeight: CGFloat = 26 {
        didSet {
            guard hasCustomizedHeight else { return }
            notchClosedSize.height = collapsedHeight
            UserDefaults.standard.set(collapsedHeight, forKey: "collapsedHeight")
        }
    }
    var notchClosedSize: CGSize = .init(width: 165, height: 26)
    var notchOpenedSize: CGSize = .init(width: 480, height: 190)

    /// 根据屏幕尺寸自适应计算 pill 大小，保证不同 Mac 上视觉一致
    func recomputeAdaptiveSizes(for screen: NSScreen? = nil) {
        let sr = screen?.frame ?? screenRect
        guard sr.width > 0, sr.height > 0 else { return }

        let sw = sr.width
        let sh = sr.height
        let menuBarH = sh - (screen?.visibleFrame.height ?? sh)
        let hasNotch = menuBarH >= 30

        // 收起态：宽度 ~15% 屏幕宽（180~230），高度按有无刘海自适应
        let closedW = (sw * 0.13).clamped(to: 155...220)
        let defaultClosedH: CGFloat = hasNotch ? 26 : 22

        // 展开态：宽度 ~35% 屏幕宽（420~580），高度 ~21%（170~230）
        let expandedW = (sw * 0.35).clamped(to: 420...580)
        let expandedH = (sh * 0.21).clamped(to: 170...230)

        notchClosedSize.width = closedW
        notchOpenedSize = CGSize(width: expandedW, height: expandedH)

        // 只有用户没手动改过高度时才更新默认值
        if !hasCustomizedHeight {
            collapsedHeight = defaultClosedH
            notchClosedSize.height = defaultClosedH
        }
    }

    /// 窗口高度：展开态高度 + 顶部余量（容纳 pill 弧形过渡）
    static var windowHeight: CGFloat { shared.notchOpenedSize.height + 20 }

    var effectiveHeight: CGFloat {
        switch status {
        case .closed: notchClosedSize.height
        case .opened: notchOpenedSize.height
        }
    }

    var effectiveWidth: CGFloat {
        if status == .opened { return notchOpenedSize.width }
        if isMusicPlaying || activeNotification != nil { return 200 }
        return notchClosedSize.width
    }

    @Published var isMusicPlaying: Bool = false
    @Published var activeNotification: IncomingNotification?

    // MARK: - 发布状态

    @Published var status: Status = .closed {
        didSet {
            NotificationCenter.default.post(
                name: NSNotification.Name("NotchStatusDidChange"), object: nil)
        }
    }
    /// 折叠态内容延迟显示（避免 cover 在 pill 动画结束前弹出）
    @Published var showCollapsedContent = true
    @Published var isHovering = false
    @Published var screenRect: CGRect = .zero
    @Published var activeTab: NotchTab = .home
    @Published var showSettings: Bool = false
    @Published var showQClawChat: Bool = false
    @Published var mirrorEnabled: Bool = true {
        didSet { UserDefaults.standard.set(mirrorEnabled, forKey: "mirrorEnabled") }
    }
    @Published var autoCloseSeconds: Double = 2.0 {
        didSet { UserDefaults.standard.set(autoCloseSeconds, forKey: "autoCloseSeconds") }
    }
    @Published var selectedCalendarIDs: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(selectedCalendarIDs), forKey: "selectedCalendarIDs")
        }
    }

    // MARK: - 全局事件监听器（核心交互）

    private var mouseMoveMonitor: EventMonitor?
    private var mouseDownMonitor: EventMonitor?
    private var rightMouseDownMonitor: EventMonitor?
    /// 记录上一帧鼠标是否在展开区域内（用于检测离开事件）
    private var wasInsideOpened = false

    func setupEvents() {
        // 全局鼠标移动 → 控制 hover 状态
        mouseMoveMonitor = EventMonitor(mask: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let loc = NSEvent.mouseLocation
            let nearCollapsed = self.hitRect.contains(loc)
            let insideOpened = self.status == .opened && self.hitRectOpened.contains(loc)

            DispatchQueue.main.async {
                self.isHovering = nearCollapsed

                // 仅当鼠标从「展开区内」→「展开区外」时启动自动收起（防止每次移动重置 timer）
                if !insideOpened, self.wasInsideOpened {
                    self.startAutoClose()
                } else if insideOpened {
                    self.cancelAutoClose()
                }
                self.wasInsideOpened = insideOpened
            }
        }
        mouseMoveMonitor?.start()

        // 全局鼠标按下 → 开/关
        mouseDownMonitor = EventMonitor(mask: .leftMouseDown) { [weak self] _ in
            guard let self else { return }
            let loc = NSEvent.mouseLocation
            DispatchQueue.main.async {
                switch self.status {
                case .opened:
                    if !self.hitRectOpened.contains(loc) {
                        self.closeNotch()
                    }
                case .closed:
                    if self.hitRect.contains(loc) {
                        self.openNotch()
                    }
                }
            }
        }
        mouseDownMonitor?.start()

        // 右键 → 退出菜单（折叠态 pill 上右键弹出 Quit）
        rightMouseDownMonitor = EventMonitor(mask: .rightMouseDown) { [weak self] _ in
            guard let self else { return }
            let loc = NSEvent.mouseLocation
            if self.status == .closed, self.hitRect.contains(loc) {
                DispatchQueue.main.async { self.showQuitMenu() }
            }
        }
        rightMouseDownMonitor?.start()
    }

    func destroy() {
        mouseMoveMonitor?.stop()
        mouseDownMonitor?.stop()
        rightMouseDownMonitor?.stop()
    }

    // MARK: - 命中区域

    /// 折叠态命中区（用于 hover + click 检测）
    var hitRect: CGRect {
        let w = effectiveWidth, h = notchClosedSize.height
        let x = screenRect.origin.x + (screenRect.width - w) / 2
        let y = screenRect.origin.y + screenRect.height - h
        return CGRect(x: x, y: y, width: w, height: h)
            .insetBy(dx: inset, dy: inset)
    }

    /// 展开态命中区
    var hitRectOpened: CGRect {
        let w = notchOpenedSize.width, h = notchOpenedSize.height
        let x = screenRect.origin.x + (screenRect.width - w) / 2
        let y = screenRect.origin.y + screenRect.height - h
        return CGRect(x: x, y: y, width: w, height: h)
            .insetBy(dx: inset, dy: inset)
    }

    /// 用户通过设置面板调节高度时调用（标记为已自定义）
    func setCustomCollapsedHeight(_ h: CGFloat) {
        hasCustomizedHeight = true
        collapsedHeight = h
        notchClosedSize.height = h
        UserDefaults.standard.set(h, forKey: "collapsedHeight")
    }

    let animation: Animation = .interactiveSpring(
        duration: 0.5, extraBounce: 0.2, blendDuration: 0.125)

    var tabTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96)),
            removal: .opacity)
    }

    // MARK: - 坐标计算（用于窗口内容定位）

    var notchRect: CGRect {
        CGRect(
            x: screenRect.origin.x + (screenRect.width - effectiveWidth) / 2,
            y: screenRect.origin.y + screenRect.height - effectiveHeight,
            width: effectiveWidth,
            height: effectiveHeight)
    }

    var notchRectInWindow: CGRect {
        let w = effectiveWidth, h = effectiveHeight
        if status == .opened {
            return CGRect(x: 0, y: 0, width: screenRect.width, height: Self.windowHeight)
        }
        return CGRect(x: (screenRect.width - w) / 2, y: Self.windowHeight - h,
                      width: w, height: h)
    }

    // MARK: - 状态变换

    func openNotch() {
        showCollapsedContent = false
        withAnimation(animation) { status = .opened }
        cancelAutoClose()
    }

    func closeNotch() {
        showCollapsedContent = false
        withAnimation(animation) { status = .closed }
        cancelAutoClose()
        // 延迟显示折叠态内容，等 pill 动画收缩到接近完成（避免封面过早弹出）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.showCollapsedContent = true
        }
    }

    // MARK: - 自动收起

    private var autoCloseTimer: Timer?

    func startAutoClose() {
        cancelAutoClose()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: autoCloseSeconds, repeats: false) { [weak self] _ in
            self?.closeNotch()
        }
    }

    func cancelAutoClose() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }

    // MARK: - 右键退出菜单

    private func showQuitMenu() {
        let menu = NSMenu()
        let item = NSMenuItem(
            title: "退出 DynamicNotch",
            action: #selector(quitApplication),
            keyEquivalent: ""
        )
        item.target = self
        menu.addItem(item)
        let point = NSEvent.mouseLocation
        menu.popUp(positioning: nil, at: point, in: nil)
    }

    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 通知

    func receiveNotification(_ noti: IncomingNotification) {
        activeNotification = noti
        if status == .closed { openNotch() }
        cancelAutoClose()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.activeNotification = nil
            }
            self?.closeNotch()
        }
    }

    func dismissNotification() {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeNotification = nil
        }
    }

    func openNotificationApp() {
        guard let noti = activeNotification else { return }
        NotificationManager.openApp(bundleID: noti.appBundleID)
        dismissNotification()
        closeNotch()
    }

    // MARK: - 隔空投送（拖拽文件）

    @Published var isDragTargetActive: Bool = false
    @Published var pendingAirDropFile: AirDropFile?
    private var airDropService: NSSharingService?

    /// 拖拽进入触发区（距 notch 200pt 内，约 pill 面积 4~5 倍）→ 展开
    func handleDragEntered(at screenLoc: NSPoint) {
        let trigger = hitRect.insetBy(dx: -200, dy: -200)
        guard trigger.contains(screenLoc) else { return }
        if status != .opened { openNotch() }
        isDragTargetActive = true
    }

    /// 拖拽离开视图区域
    func handleDragExited() {
        isDragTargetActive = false
    }

    /// 文件释放到 notch → 拷贝 → 展示文件卡片 → 弹出 AirDrop
    func handleDrop(urls: [URL]) {
        guard let url = urls.first else { return }
        isDragTargetActive = false

        // 先清理旧文件（第二个文件拖入时覆盖第一个）
        cleanupAirDropFile()

        // 拷贝到缓存目录（文件在原位置保留）
        let cacheDir = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Caches/DynamicNotch/AirDrop")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let dest = cacheDir.appendingPathComponent(url.lastPathComponent)
        let destURL = dest.uniqueName()
        try? FileManager.default.copyItem(at: url, to: destURL)

        let typeName = destURL.pathExtension.isEmpty ? "文件" : destURL.pathExtension.uppercased()
        let icon = NSWorkspace.shared.icon(forFile: destURL.path)
        let file = AirDropFile(
            name: url.lastPathComponent,
            type: typeName,
            icon: icon,
            localURL: destURL
        )
        pendingAirDropFile = file
        presentAirDrop(with: [destURL])
    }

    private func presentAirDrop(with urls: [URL]) {
        let service = NSSharingService(named: .sendViaAirDrop)
        guard let service, service.canPerform(withItems: urls) else {
            DispatchQueue.main.async { [weak self] in
                self?.cleanupAirDropFile()
                let alert = NSAlert()
                alert.messageText = "隔空投送不可用"
                alert.informativeText = "请检查 Wi-Fi 是否开启。"
                alert.runModal()
            }
            return
        }
        airDropService = service
        service.delegate = self
        service.perform(withItems: urls)
    }

    /// 清理 AirDrop 缓存文件和所有状态
    private func cleanupAirDropFile() {
        if let prev = pendingAirDropFile {
            try? FileManager.default.removeItem(at: prev.localURL)
        }
        pendingAirDropFile = nil
        airDropService = nil
    }

    /// 用户手动关闭 AirDrop 卡片（右上角 ❌ 按钮）
    func dismissAirDropFile() {
        cleanupAirDropFile()
    }

    // MARK: - 缓存清理

    /// 启动时清理过期缓存，防止无限增长
    static func cleanupStaleCaches() {
        let fm = FileManager.default
        let home = NSHomeDirectory()

        // 1. 清理 AirDrop 残留（app 崩溃留下的）
        let airdropDir = URL(fileURLWithPath: home)
            .appendingPathComponent("Library/Caches/DynamicNotch/AirDrop")
        if let files = try? fm.contentsOfDirectory(at: airdropDir,
            includingPropertiesForKeys: nil) {
            for f in files { try? fm.removeItem(at: f) }
        }

        // 2. 清理 TrayDrop — 保留最新的 20 个文件
        let trayDir = URL(fileURLWithPath: home)
            .appendingPathComponent("Library/Caches/DynamicNotch/TrayDrop")
        if let files = try? fm.contentsOfDirectory(at: trayDir,
            includingPropertiesForKeys: [.contentModificationDateKey]) {
            let sorted = files.sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return da > db
            }
            for f in sorted.dropFirst(20) {
                try? fm.removeItem(at: f)
            }
        }

        // 3. 截断诊断日志（保留最后 512KB）
        let logPath = "/tmp/notch_wc.log"
        if fm.fileExists(atPath: logPath),
           let attrs = try? fm.attributesOfItem(atPath: logPath),
           let size = attrs[.size] as? Int, size > 512_000 {
            if let fh = FileHandle(forUpdatingAtPath: logPath) {
                defer { try? fh.close() }
                let keepSize = 512_000
                let seekOffset = UInt64(size - keepSize)
                if #available(macOS 10.15.4, *) {
                    try? fh.seek(toOffset: seekOffset)
                } else {
                    fh.seek(toFileOffset: seekOffset)
                }
                let tail = fh.readDataToEndOfFile()
                try? fh.truncate(atOffset: 0)
                let marker = "[truncated]\n".data(using: .utf8)!
                try? fh.write(contentsOf: marker + tail)
            }
        }
    }
}

struct AirDropFile {
    let name: String
    let type: String
    let icon: NSImage
    let localURL: URL
}

// MARK: - NSSharingServiceDelegate

extension NotchViewModel: NSSharingServiceDelegate {
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        cleanupAirDropFile()
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: any Error) {
        cleanupAirDropFile()
    }
}

// MARK: - 通知数据模型

struct IncomingNotification: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let appBundleID: String
    let appName: String
    let timestamp: Date
    var delivered: Bool = false

    static func == (lhs: IncomingNotification, rhs: IncomingNotification) -> Bool {
        lhs.id == rhs.id
    }
}