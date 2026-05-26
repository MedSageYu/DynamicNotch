import SwiftUI

/// 3 个页面
enum NotchTab: CaseIterable {
    case home    // 音乐 + 镜子 + 日历
    case airdrop // AirDrop + 文件托盘
    case more    // 其他功能

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .airdrop: "antenna.radiowaves.left.and.right"
        case .more: "ellipsis"
        }
    }

    var label: String {
        switch self {
        case .home: "主页"
        case .airdrop: "隔空"
        case .more: "更多"
        }
    }
}