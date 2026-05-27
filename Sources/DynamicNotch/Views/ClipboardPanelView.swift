import SwiftUI

// MARK: - 剪贴板历史面板（Tab 3）

struct ClipboardPanelView: View {
    @ObservedObject private var clip = ClipboardManager.shared
    @State private var hoveredId: UUID?
    @State private var copiedId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // ── 顶部栏 ──
            header

            Divider().background(.white.opacity(0.08))

            // ── 列表 ──
            if clip.items.isEmpty {
                emptyState
            } else {
                listView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 顶部栏

    private var header: some View {
        HStack {
            Label("剪贴板", systemImage: "doc.on.clipboard")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text("\(clip.items.count)/20")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
            if !clip.items.isEmpty {
                Button { clip.clearAll() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
                .help("清空全部")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.15))
            Text("暂无记录")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
            Text("复制文字后自动记录")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.2))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 列表

    private var listView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 1) {
                ForEach(clip.items) { item in
                    ClipboardItemRow(
                        item: item,
                        isHovered: hoveredId == item.id,
                        isCopied: copiedId == item.id,
                        onHover: { hovering in
                            hoveredId = hovering ? item.id : nil
                        },
                        onTap: {
                            clip.copy(item)
                            copiedId = item.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if copiedId == item.id { copiedId = nil }
                            }
                        },
                        onDelete: { clip.remove(item) }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 单条剪贴板条目

private struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let isCopied: Bool
    let onHover: (Bool) -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // 内容
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(timeAgo)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
            }

            Spacer(minLength: 0)

            // 操作按钮（hover 时显示）
            if isHovered {
                HStack(spacing: 6) {
                    if isCopied {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Button { onDelete() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isHovered ? Color.white.opacity(0.06) : Color.clear
        )
        .contentShape(Rectangle())
        .onHover(perform: onHover)
        .onTapGesture(perform: onTap)
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(item.timestamp)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60)) 分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600)) 小时前" }
        return "\(Int(interval / 86400)) 天前"
    }
}
