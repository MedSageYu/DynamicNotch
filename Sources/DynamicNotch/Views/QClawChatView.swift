import SwiftUI
import AppKit

// MARK: - QClaw 原生聊天界面

struct QClawChatView: View {
    @ObservedObject var vm: NotchViewModel
    @StateObject private var chat = QClawChatModel()

    var body: some View {
        VStack(spacing: 0) {
            // ── 顶部栏 ──
            HStack {
                Label("QClaw AI", systemImage: "brain.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { vm.showQClawChat = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)

            Divider().background(.white.opacity(0.08))

            // ── 消息列表 ──
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(chat.messages) { msg in
                            MessageBubble(msg: msg)
                                .id(msg.id)
                        }
                        if chat.isThinking {
                            HStack {
                                ThinkingDots()
                                Spacer()
                            }.padding(.horizontal, 12)
                        }
                    }.padding(.vertical, 8)
                }
                .onChange(of: chat.messages.count) { _ in
                    withAnimation { proxy.scrollTo(chat.messages.last?.id, anchor: .bottom) }
                }
            }

            Divider().background(.white.opacity(0.08))

            // ── 输入框 ──
            HStack(spacing: 8) {
                TextField("问点什么...", text: $chat.input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .onSubmit { chat.send() }
                    .disabled(chat.isThinking)

                Button { chat.send() } label: {
                    Image(systemName: chat.isThinking ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(chat.input.isEmpty && !chat.isThinking ? .white.opacity(0.2) : .cyan)
                }.buttonStyle(.plain)
                    .disabled(chat.input.isEmpty && !chat.isThinking)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}

// MARK: - 消息气泡

private struct MessageBubble: View {
    let msg: QClawMessage

    var body: some View {
        HStack {
            if msg.isUser { Spacer(minLength: 40) }
            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 2) {
                Text(msg.text)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(msg.isUser ? 0.9 : 0.75))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(msg.isUser ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                    )
            }
            if !msg.isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - 思考中动画

private struct ThinkingDots: View {
    @State private var phase = 0.0
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 5, height: 5)
                    .scaleEffect(phase == Double(i) ? 1.3 : 0.7)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
        .onAppear { phase = 2 }
    }
}

// MARK: - 数据模型

@MainActor
final class QClawChatModel: ObservableObject {
    @Published var messages: [QClawMessage] = []
    @Published var input = ""
    @Published var isThinking = false

    private let cliPath: String = {
        let p = NSHomeDirectory()
            + "/Library/Application Support/QClaw/openclaw/config/bin/openclaw"
        return FileManager.default.isExecutableFile(atPath: p) ? p : ""
    }()

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        if cliPath.isEmpty {
            messages.append(.init(text: "❌ openclaw CLI 未找到", isUser: false))
            return
        }

        input = ""
        messages.append(.init(text: text, isUser: true))
        isThinking = true

        let msgText = text
        Task.detached { [weak self] in
            let response = await self?.callCLI(msgText)
            await MainActor.run {
                self?.isThinking = false
                if let r = response, !r.isEmpty {
                    self?.messages.append(.init(text: r, isUser: false))
                } else {
                    self?.messages.append(.init(text: "⚠️ 无响应，请稍后重试", isUser: false))
                }
            }
        }
    }

    private func callCLI(_ message: String) async -> String? {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                let pipe = Pipe()
                proc.executableURL = URL(fileURLWithPath: self.cliPath)
                proc.arguments = ["agent", "--message", message]
                proc.standardOutput = pipe
                proc.standardError = FileHandle.nullDevice
                proc.environment = ProcessInfo.processInfo.environment

                do {
                    try proc.run()
                    let data = pipe.fileHandleForReading.readData(ofLength: 64 * 1024)
                    proc.waitUntilExit()
                    let output = String(data: data, encoding: .utf8) ?? ""

                    // 从输出中提取 AI 回复（跳过插件日志行）
                    let lines = output.components(separatedBy: "\n")
                    var reply = ""
                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        // 跳过插件日志、空行
                        if trimmed.isEmpty { continue }
                        if trimmed.hasPrefix("[") { continue }
                        if trimmed.contains("init") || trimmed.contains("register") { continue }
                        if trimmed.contains("✓") || trimmed.contains("⚡") { continue }
                        if trimmed.contains("plugin") || trimmed.contains("middleware") { continue }
                        if trimmed.contains("proxy") || trimmed.contains("fetch") { continue }
                        // 有效回复行
                        if !trimmed.isEmpty && reply.isEmpty {
                            reply = trimmed
                        } else if !trimmed.isEmpty {
                            reply += "\n" + trimmed
                        }
                    }
                    cont.resume(returning: reply.isEmpty ? output : reply)
                } catch {
                    cont.resume(returning: nil)
                }
            }
        }
    }
}

struct QClawMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let date = Date()
}
