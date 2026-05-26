import SwiftUI
import WebKit

// MARK: - QClaw WebChat 面板

/// 在灵动岛内嵌入 QClaw 的 Web 控制台，实现 AI 对话
struct QClawChatView: View {
    @ObservedObject var vm: NotchViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏：标题 + 关闭
            HStack {
                Label("QClaw AI", systemImage: "brain.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        vm.showQClawChat = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // WebView 主体
            QClawWebView()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - WKWebView 封装

private struct QClawWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // 允许内联播放、本地存储等
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // 注入 CSS 隐藏不必要的 UI 元素，适配小尺寸
        let hideCSS = """
        (function() {
            var style = document.createElement('style');
            style.textContent = `
                /* 隐藏导航栏和侧边栏 */
                nav, .sidebar, .nav, header, .header, .topbar, .top-bar,
                [class*="sidebar"], [class*="Sidebar"], [class*="nav_"],
                [class*="header"], [class*="Header"], [class*="topbar"],
                [class*="drawer"], [class*="Drawer"] {
                    display: none !important;
                }
                /* 调整主内容区域占满空间 */
                main, .main, .content, .chat, [class*="main"],
                [class*="content"], [class*="chat"], [class*="Chat"] {
                    margin: 0 !important;
                    padding: 4px !important;
                    max-width: 100% !important;
                }
                /* 紧凑字体 */
                body { font-size: 12px !important; }
                /* 暗色背景适配 */
                body { background: #0a0a0a !important; }
            `;
            document.head.appendChild(style);
        })();
        """
        let script = WKUserScript(source: hideCSS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false

        if let url = URL(string: "http://127.0.0.1:28789") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}