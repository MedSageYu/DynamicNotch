import SwiftUI
import AppKit

// MARK: - 剪贴板条目

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let timestamp: Date
    var preview: String {
        text.replacingOccurrences(of: "\n", with: " ")
            .prefix(80)
            .description
    }
}

// MARK: - 剪贴板管理器（单例，轮询 NSPasteboard）

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var items: [ClipboardItem] = []

    private let maxItems = 20
    private var changeCount: Int = 0
    private var timer: Timer?

    private init() {
        changeCount = NSPasteboard.general.changeCount
        startPolling()
    }

    deinit { timer?.invalidate() }

    // MARK: - 轮询

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != changeCount else { return }
        changeCount = pb.changeCount

        // 只读取纯文本
        guard let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        // 去重：如果和最近一条一样就不添加
        if let first = items.first, first.text == text { return }

        let item = ClipboardItem(text: text, timestamp: Date())
        items.insert(item, at: 0)

        // 超过 maxItems 自动清理
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
    }

    // MARK: - 操作

    /// 复制到剪贴板
    func copy(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
    }

    /// 删除单条
    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    /// 清空全部
    func clearAll() {
        items.removeAll()
    }
}
