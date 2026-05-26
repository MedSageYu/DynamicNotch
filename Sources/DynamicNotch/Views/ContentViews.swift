import SwiftUI
import EventKit

// MARK: - 文件托盘

struct FileTrayView: View {
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isTargeted ? "tray.and.arrow.down.fill" : "tray")
                .font(.system(size: 24))
                .foregroundColor(isTargeted ? .white : .white.opacity(0.4))
            Text(isTargeted ? "松开放入" : "拖放文件")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(isTargeted ? 0.4 : 0.15), lineWidth: 1))
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url { print("[FileTray] dropped: \(url.path)") }
                }
            }
            return true
        }
    }
}

// MARK: - 紧凑日历（5 天 x 滑动翻页）

struct CompactCalendarView: View {
    @ObservedObject var vm: NotchViewModel
    @State private var selectedDate = Date()
    @State private var events: [EKEvent] = []
    @State private var calendarAccess: Bool?
    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            // ── 5 天横条（TabView page 滑动翻页）──
            weekStrip

            // ── 日程 ──
            if calendarAccess == false {
                noPermHint
            } else if events.isEmpty {
                emptyHint
            } else {
                eventList
            }

            // ── 回到今天 ──
            if !cal.isDate(selectedDate, inSameDayAs: Date()) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = Date()
                    }
                    loadEvents()
                } label: {
                    Text("今天").font(.system(size: 8)).foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 3).padding(.vertical, 4)
        .onAppear(perform: requestThenLoad)
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in loadEvents() }
        .onChange(of: vm.selectedCalendarIDs) { _, _ in loadEvents() }
    }

    // MARK: - 权限 + 加载

    private func requestThenLoad() {
        calendarAccess = nil
        CalendarStore.shared.requestAccess { [self] granted in
            calendarAccess = granted
            loadEvents()
        }
    }

    private func loadEvents() {
        let store = CalendarStore.shared.store
        let access = EKEventStore.authorizationStatus(for: .event)
        guard access == .authorized || access == .fullAccess else { return }

        let start = cal.startOfDay(for: selectedDate)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return }

        let selectedIDs = vm.selectedCalendarIDs
        let calendars: [EKCalendar]?
        if selectedIDs.isEmpty {
            calendars = nil
        } else {
            calendars = store.calendars(for: .event).filter { selectedIDs.contains($0.calendarIdentifier) }
        }
        let p = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        events = store.events(matching: p).sorted { $0.startDate < $1.startDate }
    }

    // MARK: - 日期横条（双指滑动，显示前后 5 天）

    private var weekStrip: some View {
        let today = cal.startOfDay(for: Date())
        let days = (-5...5).compactMap { cal.date(byAdding: .day, value: $0, to: today) }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                    let isSel = cal.isDate(d, inSameDayAs: selectedDate)
                    let isTod = cal.isDate(d, inSameDayAs: today)
                    DayCell(date: d, isSelected: isSel, isToday: isTod)
                        .frame(width: 24, height: 28)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedDate = d
                            }
                            loadEvents()
                        }
                }
            }
        }
        .defaultScrollAnchor(.center)
        .frame(height: 30)
    }

    // MARK: - 日程区域

    private var emptyHint: some View {
        if let _ = calendarAccess {} else {
            Text("…").font(.system(size: 8)).foregroundColor(.white.opacity(0.2))
                .frame(maxWidth: .infinity).padding(.vertical, 2)
        }
        let label = cal.isDate(selectedDate, inSameDayAs: Date())
            ? "今天无日程" : "无日程"
        return Text(label).font(.system(size: 8))
            .foregroundColor(.white.opacity(0.25))
            .frame(maxWidth: .infinity).padding(.vertical, 4)
    }

    private var noPermHint: some View {
        Text("无权限").font(.system(size: 8))
            .foregroundColor(.white.opacity(0.4))
            .frame(maxWidth: .infinity).padding(.vertical, 4)
    }

    private var eventList: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(events.prefix(3)), id: \.eventIdentifier) { ev in
                CompactEventBar(ev: ev)
            }
        }
        .padding(.top, 1)
    }
}

// MARK: - 单日格子（极简）

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    private let cal = Calendar.current
    private let wdays = ["日","一","二","三","四","五","六"]

    var body: some View {
        let wd = wdays[cal.component(.weekday, from: date) - 1]
        let dn = "\(cal.component(.day, from: date))"
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.2))
            } else if isToday {
                RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.08))
            }
            VStack(spacing: 0) {
                Text(wd)
                    .font(.system(size: 6)).foregroundColor(
                        isSelected ? .white.opacity(0.7) : .white.opacity(0.3))
                Text(dn)
                    .font(.system(size: 10, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundColor(
                        isSelected ? .white : .white.opacity(0.7))
            }
        }
    }
}

// MARK: - 紧凑日程条

private struct CompactEventBar: View {
    let ev: EKEvent
    private var c: Color { Color(ev.calendar.color) }

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1).fill(c).frame(width: 2)
            Text(ev.title)
                .font(.system(size: 7.5)).foregroundColor(.white.opacity(0.8)).lineLimit(1)
            Spacer()
            Text(ev.isAllDay ? "全天" : timeShort)
                .font(.system(size: 6.5)).foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 3).padding(.vertical, 1.5)
        .background(RoundedRectangle(cornerRadius: 3).fill(c.opacity(0.08)))
    }

    private var timeShort: String {
        guard let s = ev.startDate else { return "" }
        let h = Calendar.current.component(.hour, from: s)
        let m = Calendar.current.component(.minute, from: s)
        return "\(h):\(String(format: "%02d", m))"
    }
}

// MARK: - CalendarStore

final class CalendarStore: ObservableObject {
    static let shared = CalendarStore()
    let store = EKEventStore()
    private init() {}

    func requestAccess(completion: @escaping (Bool) -> Void) {
        let handler: (Bool, (any Error)?) -> Void = { ok, _ in
            DispatchQueue.main.async { completion(ok) }
        }
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents(completion: handler)
        } else {
            store.requestAccess(to: .event, completion: handler)
        }
    }

    var allCalendars: [EKCalendar] { store.calendars(for: .event) }
}

// MARK: - AI 占位

struct AIViewPlaceholder: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "brain.fill").font(.system(size: 28)).foregroundColor(.purple.opacity(0.6))
            Text("QClaw AI").font(.system(size: 12)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}