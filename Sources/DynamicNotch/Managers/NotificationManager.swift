import Cocoa
import UserNotifications

/// 通知管理器
/// 监听 iMessage / 邮件 通知 → 转发给 NotchViewModel 展示
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private var observers: [NSObjectProtocol] = []

    /// 已知的 App 分布式通知（bundleID → 名称 + 通知名）
    private let mapping: [(bundleID: String, name: String, notifyName: String, fallbackTitle: String)] = [
        // iMessage / 信息
        ("com.apple.iChat",   "信息",   "com.apple.iChat.MessageReceived",       "新消息"),
        // 邮件
        ("com.apple.mail",    "邮件",   "com.apple.mail.newMessagesNotification", "新邮件"),
    ]

    private override init() {
        super.init()
        setupNotificationCenterDelegate()
    }

    deinit { tearDown() }

    // MARK: - 监听启动

    func startListening() {
        print("[NotificationManager] 开始监听通知...")

        for (bid, name, noti, fallback) in mapping {
            // 检查 App 是否已安装
            guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) != nil else {
                continue
            }
            print("[NotificationManager] 监听 \(name) (\(noti))")

            let obs = DistributedNotificationCenter.default()
                .addObserver(forName: NSNotification.Name(noti), object: nil, queue: .main) { [weak self] note in
                    self?.handleDistributedNotification(note, appName: name, bundleID: bid, fallback: fallback)
                }
            observers.append(obs)
        }

        // 通用通知中心监听
        let generalObs = DistributedNotificationCenter.default()
            .addObserver(forName: NSNotification.Name("com.apple.notificationcenter.notification"), object: nil, queue: .main) { [weak self] note in
                self?.handleNotificationCenter(note)
            }
        observers.append(generalObs)
    }

    func tearDown() {
        for obs in observers { DistributedNotificationCenter.default().removeObserver(obs) }
        observers.removeAll()
    }

    // MARK: - 通知处理

    private func handleDistributedNotification(_ note: Notification, appName: String, bundleID: String, fallback: String) {
        print("[NotificationManager] 📬 \(appName): \(note.userInfo ?? [:])")

        let notification = IncomingNotification(
            title: fallback,
            subtitle: appName,
            appBundleID: bundleID,
            appName: appName,
            timestamp: Date()
        )
        DispatchQueue.main.async {
            NotchViewModel.shared.receiveNotification(notification)
        }
    }

    private func handleNotificationCenter(_ note: Notification) {
        guard let userInfo = note.userInfo else { return }
        let title = (userInfo["title"] as? String)
            ?? (userInfo["Title"] as? String)
            ?? "通知"
        let subtitle = (userInfo["subtitle"] as? String)
            ?? (userInfo["Subtitle"] as? String)
            ?? (userInfo["body"] as? String)
            ?? ""

        print("[NotificationManager] 📬 通用通知: \(title) — \(subtitle)")

        let notification = IncomingNotification(
            title: title,
            subtitle: subtitle,
            appBundleID: "",
            appName: "",
            timestamp: Date()
        )
        DispatchQueue.main.async {
            NotchViewModel.shared.receiveNotification(notification)
        }
    }

    // MARK: - UserNotifications Delegate

    private func setupNotificationCenterDelegate() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("[NotificationManager] 通知权限: \(granted ? "✅" : "❌"), 错误: \(error?.localizedDescription ?? "无")")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let req = notification.request
        let noti = IncomingNotification(
            title: req.content.title,
            subtitle: req.content.subtitle,
            appBundleID: req.content.targetContentIdentifier ?? "",
            appName: "",
            timestamp: Date()
        )
        DispatchQueue.main.async {
            NotchViewModel.shared.receiveNotification(noti)
        }
        completionHandler([])
    }

    // MARK: - 打开 App

    static func openApp(bundleID: String) {
        guard !bundleID.isEmpty else { return }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.open(url)
        }
    }
}