import AppKit

/// 全局 + 本地事件监听器
/// ⚠️ macOS 限制：NSEvent.addGlobalMonitorForEvents 不接收 mouseMoved（事件量太大）
/// → mouseMoved 改用 Timer 轮询 NSEvent.mouseLocation
final class EventMonitor {
    private var globalMonitor: AnyObject?
    private var localMonitor: AnyObject?
    private var pollingTimer: Timer?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit { stop() }

    func start() {
        let needsMouseMoved = mask.contains(.mouseMoved)
        let otherMasks = NSEvent.EventTypeMask(rawValue: mask.rawValue & ~NSEvent.EventTypeMask.mouseMoved.rawValue)

        // 全局监听 — 用于 leftMouseDown / leftMouseUp 等（不包含 mouseMoved）
        if !otherMasks.isEmpty {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: otherMasks, handler: handler) as AnyObject?
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: otherMasks) { [weak self] event in
                self?.handler(event)
                return event
            } as AnyObject?
        }

        // mouseMoved → Timer 轮询（NSEvent 全局监听不支持 mouseMoved）
        if needsMouseMoved {
            pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                let fakeEvent = NSEvent.mouseEvent(with: .mouseMoved,
                    location: NSEvent.mouseLocation,
                    modifierFlags: [],
                    timestamp: 0,
                    windowNumber: 0,
                    context: nil,
                    eventNumber: 0,
                    clickCount: 0,
                    pressure: 0)!
                self?.handler(fakeEvent)
            }
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        localMonitor = nil
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}