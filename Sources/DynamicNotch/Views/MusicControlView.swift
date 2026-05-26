import SwiftUI
import AppKit
import Foundation

// MARK: - MusicControlView

struct MusicControlView: View {
    @StateObject private var musicManager = MusicManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if let track = musicManager.currentTrack {
                // 歌名 + 歌手（整体缩小）
                VStack(spacing: 1) {
                    Text(track)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if let artist = musicManager.currentArtist, !artist.isEmpty {
                        Text(artist)
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 5)

                // 封面（固定尺寸 64×64）
                ZStack {
                    if let art = musicManager.artworkImage {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .cornerRadius(10)
                    } else if let icon = musicManager.currentAppIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .cornerRadius(10)
                            .opacity(0.5)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .padding(.bottom, 6)

                // 控制按钮：上一步 / 播放暂停 / 下一步（整体缩小）
                HStack(spacing: 16) {
                    Button { musicManager.previousTrack() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }.buttonStyle(.plain)

                    Button { musicManager.togglePlayPause() } label: {
                        Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }.buttonStyle(.plain)

                    Button { musicManager.nextTrack() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }.buttonStyle(.plain)
                }
            } else {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                        Text("未在播放音乐")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("在 Apple Music 播放歌曲")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
        .onAppear { MusicManager.shared.refreshNowPlaying() }
    }
}

// MARK: - MusicManager

final class MusicManager: ObservableObject {
    static let shared = MusicManager()

    @Published var isPlaying = false
    @Published var currentTrack: String?
    @Published var currentArtist: String?
    @Published var currentAlbum: String?
    @Published var artworkImage: NSImage?
    @Published var currentAppIcon: NSImage?
    @Published var volume: Float = 0.5

    private var timer: Timer?

    private init() {
        loadAppIcons()
        refreshNowPlaying()
        startPolling()
        // 异步读取系统音量——Process.capture() 的 waitUntilExit()
        // 会在主线程泵送 RunLoop，嵌套 SwiftUI 布局 → SIGABRT
        DispatchQueue.main.async { [weak self] in
            self?.volume = self?.getSystemVolume() ?? 0.5
        }
    }

    deinit { timer?.invalidate() }

    // MARK: - 主查询：AppleScript + 封面导出

    func refreshNowPlaying() {
        let src = """
tell application "Music"
    if it is running then
        try
            set t to name of current track
            set a to artist of current track
            set al to album of current track
            set s to player state as text
            set artPath to ""
            try
                set d to raw data of artwork 1 of current track
                set f to POSIX file "/tmp/dn_artwork.jpg"
                set fd to open for access f with write permission
                set eof of fd to 0
                write d to fd
                close access fd
                set artPath to "/tmp/dn_artwork.jpg"
            on error
                try
                    close access POSIX file "/tmp/dn_artwork.jpg"
                end try
            end try
            return t & "|" & a & "|" & al & "|" & s & "|" & artPath
        on error
            return ""
        end try
    end if
end tell
"""
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let out = Process.capture("/usr/bin/osascript", arguments: ["-e", src])
            guard let s = out?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !s.isEmpty else {
                // AppleScript 返回空 = Music.app 已退出或无当前曲目 → 清状态
                DispatchQueue.main.async { [weak self] in
                    self?.clearTrackState()
                }
                return
            }
            let parts = s.components(separatedBy: "|")
            guard parts.count >= 3 else {
                self?.tryMediaRemoteFallback()
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.currentTrack != parts[0] || self.currentArtist != parts[1] {
                    print("[MusicManager] osascript: \(parts[0]) — \(parts[1])")
                }
                self.currentTrack = parts[0]
                self.currentArtist = parts[1]
                self.currentAlbum = parts[2]
                self.isPlaying = parts.count > 3 && parts[3].contains("playing")
                // 同步到灵动岛 ViewModel（折叠态音乐展示）
                NotchViewModel.shared.isMusicPlaying = self.currentTrack != nil && self.isPlaying
                // 封面：AppleScript 写到 /tmp/dn_artwork.jpg
                if parts.count > 4, !parts[4].isEmpty,
                   FileManager.default.fileExists(atPath: parts[4]),
                   let img = NSImage(contentsOfFile: parts[4]) {
                    self.artworkImage = img
                } else {
                    self.artworkImage = nil
                }
            }
            self?.tryMediaRemoteFallback()
        }
    }

    private func tryMediaRemoteFallback() {
        guard currentTrack == nil else { return }
        guard let exePath = Bundle.main.executablePath else { return }
        let path = URL(fileURLWithPath: exePath)
            .deletingLastPathComponent().appendingPathComponent("mrhelper").path
        guard FileManager.default.isExecutableFile(atPath: path) else { return }
        guard let j = Process.capture(path, arguments: [], timeout: 2), j != "{}" else { return }
        parseJSON(j)
    }

    private func clearTrackState() {
        currentTrack = nil
        currentArtist = nil
        currentAlbum = nil
        artworkImage = nil
        isPlaying = false
        NotchViewModel.shared.isMusicPlaying = false
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.refreshNowPlaying()
        }
    }

    private func parseJSON(_ json: String) {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentTrack  = obj["title"] as? String ?? ""
            self.currentArtist = obj["artist"] as? String
            self.currentAlbum  = obj["album"] as? String
            self.isPlaying     = obj["playing"] as? Bool ?? false
            // 同步到灵动岛 ViewModel
            NotchViewModel.shared.isMusicPlaying = !(self.currentTrack?.isEmpty ?? true) && self.isPlaying
            if let b64 = obj["artwork"] as? String, !b64.isEmpty,
               let d = Data(base64Encoded: b64) {
                self.artworkImage = NSImage(data: d)
            }
        }
    }

    // MARK: - 播放控制

    func togglePlayPause() {
        Process.execute("/usr/bin/osascript", arguments: ["-e", "tell application \"Music\" to playpause"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshNowPlaying()
        }
    }

    func nextTrack() {
        Process.execute("/usr/bin/osascript", arguments: ["-e", "tell application \"Music\" to next track"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshNowPlaying()
        }
    }

    func previousTrack() {
        Process.execute("/usr/bin/osascript", arguments: ["-e", "tell application \"Music\" to previous track"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshNowPlaying()
        }
    }

    // MARK: - 音量

    func setVolume(_ vol: Float) {
        volume = vol
        Process.execute("/usr/bin/osascript",
                        arguments: ["-e", "set volume output volume \(Int(vol * 100))"])
    }

    private func getSystemVolume() -> Float {
        let s = Process.capture("/usr/bin/osascript",
                                arguments: ["-e", "output volume of (get volume settings)"]) ?? "50"
        return (Float(s.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 50) / 100.0
    }

    // MARK: - App 图标

    private func loadAppIcons() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                DispatchQueue.main.async { self?.currentAppIcon = icon }
            }
        }
    }
}

// MARK: - Process 辅助

private extension Process {
    static func capture(_ exe: String, arguments: [String], timeout: TimeInterval = 5) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: exe)
        p.arguments = arguments
        let outPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return nil }
        let killAfter = DispatchWorkItem { p.terminate() }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: killAfter)
        p.waitUntilExit()
        killAfter.cancel()
        guard p.terminationStatus == 0 else { return nil }
        return String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func execute(_ exe: String, arguments: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: exe)
        p.arguments = arguments
        p.standardOutput = FileHandle.nullDevice
        p.standardError  = FileHandle.nullDevice
        try? p.run()
    }
}
