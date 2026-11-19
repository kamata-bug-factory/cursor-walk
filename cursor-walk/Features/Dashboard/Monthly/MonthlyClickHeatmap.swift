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
            initialValue: Calendar.current.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
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

        MonthlyHeatmap(
            month: data.month,
            days: data.days,
            date: \.date,
            intensityLevel: \.intensityLevel,
            isInDisplayedMonth: \.isInDisplayedMonth,
            hasValue: \.hasValue,
            totalText: "合計 \(ClickFormatter.countWithUnit(data.totalClicks.total))",
            legendAccessibilityLabel: "クリック回数の色。薄いほど少なく、濃いほど多い",
            canMoveBackward: canMoveBackward,
            canMoveForward: canMoveForward,
            moveBackward: { moveMonth(by: -1) },
            moveForward: { moveMonth(by: 1) },
            accessibilityValue: { day in
                ClickFormatter.countWithUnit(day.clicks.total)
            }
        ) { day in
            ClickHeatmapTooltip(day: day)
        }
        .onChange(of: latestRecordedDay) {
            history = MonthlyClickHistory(dailyClicks: dailyClicks)
        }
    }

    private var latestRecordedDay: Date? {
        dailyClicks.last.map { Calendar.current.startOfDay(for: $0.day) }
    }

    private var canMoveBackward: Bool { displayedMonth > earliestMonth }
    private var canMoveForward: Bool { displayedMonth < currentMonth }
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
        guard let month = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }
        displayedMonth = min(max(month, earliestMonth), currentMonth)
    }
}

private struct ClickHeatmapTooltip: View {
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
