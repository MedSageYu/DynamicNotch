import Cocoa
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 隔空投送面板

/// 隔空投送面板
/// - 拖文件到该区域 → 直接 AirDrop
/// - 点击 → 打开文件选择器 → AirDrop
struct AirDropPanel: View {
    @State private var targeting = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(targeting ? 0.08 : 0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.cyan.opacity(targeting ? 0.5 : 0.2), lineWidth: 1)
                }

            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 16))
                    .foregroundStyle(.cyan)
                    .symbolEffect(.pulse, isActive: targeting)

                Text("隔空投送")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(height: 44)
        .contentShape(Rectangle())
        .onTapGesture { openFilePicker() }
        .onDrop(of: [.data], isTargeted: $targeting) { providers in
            providers.startAirDrop()
            return true
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK else { return }
            let service = NSSharingService(named: .sendViaAirDrop)
            guard let service, service.canPerform(withItems: panel.urls) else {
                NSAlert.info("隔空投送不可用，请检查设置。")
                return
            }
            service.perform(withItems: panel.urls)
        }
    }
}

// MARK: - NSItemProvider → AirDrop

extension [NSItemProvider] {
    /// 将拖入的文件通过隔空投送发送
    func startAirDrop() {
        DispatchQueue.global().async {
            let sem = DispatchSemaphore(value: 0)
            var urls: [URL] = []

            for provider in self {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url { urls.append(url) }
                    sem.signal()
                }
                sem.wait()
            }

            guard !urls.isEmpty else { return }

            DispatchQueue.main.async {
                let service = NSSharingService(named: .sendViaAirDrop)
                guard let service, service.canPerform(withItems: urls) else {
                    NSAlert.info("隔空投送不可用，请检查设置。")
                    return
                }
                service.perform(withItems: urls)
            }
        }
    }
}

// MARK: - NSAlert 辅助

extension NSAlert {
    static func info(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}
