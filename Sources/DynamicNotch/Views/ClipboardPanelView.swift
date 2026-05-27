import SwiftUI

// MARK: - 剪贴板历史面板（横向卡片滚动）

struct ClipboardPanelView: View {
    @ObservedObject private var clip = ClipboardManager.shared
    @State private var hoveredId: UUID?
    @State private var copiedId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // ── 顶部栏 ──
            header

            Divider().background(.white.opacity(0.08))

            // ── 内容 ──
            if clip.items.isEmpty {
                emptyState
            } else {
                scrollContent
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
            Text("复制文字或图片后自动记录")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.2))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 横向滚动内容

    private var scrollContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(clip.items) { item in
                    ClipboardCard(
                        item: item,
                        isHovered: hoveredId == item.id,
                        isCopied: copiedId == item.id,
                        onHover: { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredId = hovering ? item.id : nil
                            }
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
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 单张卡片（文字 / 图片）

private struct ClipboardCard: View {
    let item: ClipboardItem
    let isHovered: Bool
    let isCopied: Bool
    let onHover: (Bool) -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContent

            // 删除按钮（hover 时显示）
            if isHovered {
                Button { onDelete() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .padding(4)
            }
        }
        .frame(width: cardWidth, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(isHovered ? 0.15 : 0.06), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onHover(perform: onHover)
        .onTapGesture(perform: onTap)
    }

    // MARK: - 卡片内容

    @ViewBuilder
    private var cardContent: some View {
        switch item.content {
        case let .text(text):
            textCard(text)
        case let .image(img):
            imageCard(img)
        }
    }

    // MARK: - 文字卡片

    private func textCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // 时间
            Text(timeAgo)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))

            // 文字内容（hover 时显示更多行）
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(isHovered ? 8 : 3)
                .multilineTextAlignment(.leading)
                .animation(.easeInOut(duration: 0.15), value: isHovered)

            Spacer(minLength: 0)

            // 底部操作
            HStack {
                if isCopied {
                    Label("已复制", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.green)
                } else {
                    Text("点击复制")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.2))
                }
                Spacer()
                Text("\(text.count) 字")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.15))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - 图片卡片

    private func imageCard(_ img: NSImage) -> some View {
        ZStack {
            // 缩略图
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // 底部渐变 + 时间
            VStack {
                Spacer()
                HStack {
                    Text(timeAgo)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if isCopied {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
        }
        .frame(width: cardWidth, height: 100)
    }

    // MARK: - 卡片宽度（根据内容自适应）

    private var cardWidth: CGFloat {
        switch item.content {
        case let .text(text):
            // 短文字窄卡，长文字宽卡
            let len = text.count
            if len < 30 { return 90 }
            if len < 80 { return 130 }
            return 160
        case .image:
            return 120
        }
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(item.timestamp)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        return "\(Int(interval / 86400))天前"
    }
}
