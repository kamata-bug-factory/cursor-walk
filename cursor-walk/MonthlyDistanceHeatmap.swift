//
//  MonthlyDistanceHeatmap.swift
//  cursor-walk
//

import SwiftUI

/// 1か月の日別移動距離をカレンダー形式の濃淡で表示する。
struct MonthlyDistanceHeatmap: View {
    let dailyDistances: [DailyDistance]
    let currentDayPoints: Double
    @State private var displayedMonth: Date
    @State private var history: MonthlyDistanceHistory

    init(dailyDistances: [DailyDistance], currentDayPoints: Double) {
        let referenceDate = Date.now

        self.dailyDistances = dailyDistances
        self.currentDayPoints = currentDayPoints
        _displayedMonth = State(
            initialValue: Calendar.current.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
        )
        _history = State(
            initialValue: MonthlyDistanceHistory(
                dailyDistances: dailyDistances,
                referenceDate: referenceDate
            )
        )
    }

    var body: some View {
        let data = MonthlyDistanceData(
            month: displayedMonth,
            history: history,
            currentDayPoints: currentDayPoints
        )

        MonthlyHeatmap(
            month: data.month,
            days: data.days,
            date: \.date,
            intensityLevel: \.intensityLevel,
            isInDisplayedMonth: \.isInDisplayedMonth,
            hasValue: \.hasValue,
            totalText: "合計 \(DistanceFormatter.formattedDistance(for: data.totalPoints))",
            legendAccessibilityLabel: "移動距離の色。薄いほど少なく、濃いほど多い",
            canMoveBackward: canMoveBackward,
            canMoveForward: canMoveForward,
            moveBackward: { moveMonth(by: -1) },
            moveForward: { moveMonth(by: 1) },
            accessibilityValue: { day in
                DistanceFormatter.formattedDistance(for: day.points)
            }
        ) { day in
            DistanceHeatmapTooltip(day: day)
        }
        .onChange(of: latestRecordedDay) {
            history = MonthlyDistanceHistory(dailyDistances: dailyDistances)
        }
    }

    private var latestRecordedDay: Date? {
        dailyDistances.last.map { Calendar.current.startOfDay(for: $0.day) }
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

private struct DistanceHeatmapTooltip: View {
    let day: MonthlyDistanceDay

    var body: some View {
        Text("\(DateDisplayFormatter.yearMonthDayWeekday(from: day.date)) \(DistanceFormatter.formattedDistance(for: day.points))")
            .font(.caption)
            .tooltipStyle()
    }
}
