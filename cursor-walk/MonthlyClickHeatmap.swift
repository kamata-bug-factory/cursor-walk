//
//  MonthlyClickHeatmap.swift
//  cursor-walk
//

import SwiftUI

/// 1か月の日別クリック回数をカレンダー形式の濃淡で表示する。
struct MonthlyClickHeatmap: View {
    let dailyClicks: [DailyClickCount]
    let currentDayClicks: ClickBreakdown
    @State private var displayedMonth: Date
    @State private var history: MonthlyClickHistory

    init(dailyClicks: [DailyClickCount], currentDayClicks: ClickBreakdown) {
        let referenceDate = Date.now

        self.dailyClicks = dailyClicks
        self.currentDayClicks = currentDayClicks
        _displayedMonth = State(
            initialValue: Calendar.current.dateInterval(
                of: .month,
                for: referenceDate
            )?.start ?? referenceDate
        )
        _history = State(
            initialValue: MonthlyClickHistory(
                dailyClicks: dailyClicks,
                referenceDate: referenceDate
            )
        )
    }

    var body: some View {
        let data = MonthlyClickData(
            month: displayedMonth,
            history: history,
            currentDayClicks: currentDayClicks
        )

        VStack(alignment: .leading, spacing: 12) {
            MonthlyClickHeader(
                month: data.month,
                total: data.totalClicks.total,
                canMoveBackward: canMoveBackward,
                canMoveForward: canMoveForward,
                moveBackward: { moveMonth(by: -1) },
                moveForward: { moveMonth(by: 1) }
            )

            MonthlyClickContent(days: data.days)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: latestRecordedDay) {
            history = MonthlyClickHistory(dailyClicks: dailyClicks)
        }
    }

    private var latestRecordedDay: Date? {
        dailyClicks.last.map { Calendar.current.startOfDay(for: $0.day) }
    }

    private var canMoveBackward: Bool {
        displayedMonth > earliestMonth
    }

    private var canMoveForward: Bool {
        displayedMonth < currentMonth
    }

    private var currentMonth: Date {
        Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    private var earliestMonth: Date {
        Calendar.current.date(
            byAdding: .month,
            value: MonthlyHeatmapStyle.retainedMonthOffset,
            to: currentMonth
        ) ?? currentMonth
    }

    private func moveMonth(by value: Int) {
        guard let month = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: displayedMonth
        ) else {
            return
        }

        displayedMonth = min(max(month, earliestMonth), currentMonth)
    }
}

private struct MonthlyClickHeader: View {
    let month: Date
    let total: Int
    let canMoveBackward: Bool
    let canMoveForward: Bool
    let moveBackward: () -> Void
    let moveForward: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MonthNavigationButton(
                systemImage: "chevron.left",
                accessibilityLabel: "前の月",
                isEnabled: canMoveBackward,
                action: moveBackward
            )

            VStack(alignment: .center, spacing: 2) {
                Text(DateDisplayFormatter.yearMonth(from: month))
                    .font(.headline)
                Text("合計 \(ClickFormatter.countWithUnit(total))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: MonthlyHeatmapStyle.valueColumnWidth, alignment: .center)

            MonthNavigationButton(
                systemImage: "chevron.right",
                accessibilityLabel: "次の月",
                isEnabled: canMoveForward,
                action: moveForward
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct MonthNavigationButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringResource
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(
                    width: MonthlyHeatmapStyle.navigationButtonLength,
                    height: MonthlyHeatmapStyle.navigationButtonLength
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0)
        .frame(
            width: MonthlyHeatmapStyle.navigationButtonLength,
            height: MonthlyHeatmapStyle.navigationButtonLength
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHidden(!isEnabled)
    }
}

private struct MonthlyClickContent: View {
    let days: [MonthlyClickDay]

    var body: some View {
        VStack(spacing: 12) {
            MonthlyClickCalendar(days: days)
            MonthlyClickLegend()
        }
        .frame(width: MonthlyHeatmapStyle.calendarWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct MonthlyClickCalendar: View {
    private static let columns = Array(
        repeating: GridItem(
            .fixed(MonthlyHeatmapStyle.cellLength),
            spacing: MonthlyHeatmapStyle.cellSpacing
        ),
        count: MonthlyHeatmapStyle.weekdayCount
    )
    private static let weekdaySymbols: [String] = {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar.veryShortStandaloneWeekdaySymbols
    }()

    let days: [MonthlyClickDay]

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: Self.columns, spacing: MonthlyHeatmapStyle.cellSpacing) {
                ForEach(Self.weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: MonthlyHeatmapStyle.cellLength)
                }
            }

            LazyVGrid(columns: Self.columns, spacing: MonthlyHeatmapStyle.cellSpacing) {
                ForEach(days) { day in
                    MonthlyClickDayCell(day: day)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: MonthlyHeatmapStyle.calendarHeight, alignment: .center)
    }
}

private struct MonthlyClickDayCell: View {
    let day: MonthlyClickDay
    @State private var isHovered = false
    @State private var tooltipHeight: CGFloat = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(MonthlyHeatmapStyle.color(for: day.intensityLevel))

            if day.isInDisplayedMonth {
                Text(day.date, format: .dateTime.day())
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(day.clicks.total > 0 ? .white : .secondary)
            }
        }
        .frame(width: MonthlyHeatmapStyle.cellLength, height: MonthlyHeatmapStyle.cellLength)
        .opacity(day.isInDisplayedMonth ? 1 : 0)
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active:
                isHovered = true
            case .ended:
                isHovered = false
            }
        }
        .overlay(alignment: .top) {
            if isHovered {
                MonthlyClickTooltip(day: day)
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        tooltipHeight = height
                    }
                    .offset(y: -(tooltipHeight + MonthlyHeatmapStyle.cellSpacing))
            }
        }
        .zIndex(isHovered ? 1 : 0)
        .allowsHitTesting(day.isInDisplayedMonth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.date.formatted(.dateTime.year().month().day().weekday()))
        .accessibilityValue(ClickFormatter.countWithUnit(day.clicks.total))
        .accessibilityHidden(!day.isInDisplayedMonth)
    }
}

private struct MonthlyClickTooltip: View {
    let day: MonthlyClickDay

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateDisplayFormatter.yearMonthDayWeekday(from: day.date))
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(ClickFormatter.countWithUnit(day.clicks.total))
                    .font(.caption.weight(.semibold))
                Text(ClickFormatter.breakdown(day.clicks))
                    .font(.caption2)
            }
        }
        .tooltipStyle()
    }
}

private struct MonthlyClickLegend: View {
    var body: some View {
        HStack(spacing: 5) {
            Spacer()
            Text("少ない")
            ForEach(0..<MonthlyHeatmapStyle.legendLevelCount, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(MonthlyHeatmapStyle.color(for: level))
                    .frame(width: 12, height: 12)
            }
            Text("多い")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("クリック回数の色。薄いほど少なく、濃いほど多い")
    }
}
