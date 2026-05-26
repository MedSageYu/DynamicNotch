import SwiftUI

/// 音频波形动画 —— 折叠灵动岛上的动态音轨条
/// 仿 Apple Dynamic Island 音乐波形效果
struct WaveformView: View {
    let isPlaying: Bool
    @State private var tick: Double = 0

    /// 5 条等宽 bar，同步跳动
    private let bars = 5

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(0..<bars, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: isPlaying
                                    ? [.white.opacity(0.7), .white.opacity(0.3)]
                                    : [.white.opacity(0.2), .white.opacity(0.1)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 2.5)
                        .frame(height: barHeight(i, t: t))
                }
            }
        }
    }

    /// 每条 bar 高度独立计算，形成波形起伏
    private func barHeight(_ index: Int, t: Double) -> CGFloat {
        guard isPlaying else { return 4 }
        let phase = Double(index) * 0.4
        let v = sin(t * 6.0 + phase)    // 快节奏主波
        let v2 = sin(t * 11.0 + phase * 1.7) * 0.3  // 高频抖动
        let amplitude = (abs(v + v2) * 0.7 + 0.3)  // 归一化到 [0.3, 1.0]
        return max(3, 14 * CGFloat(amplitude))
    }
}