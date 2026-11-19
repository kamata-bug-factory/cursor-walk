//
//  WeeklyClickData.swift
//  cursor-walk
//

import Foundation

/// 日曜始まりの今週と前週の日別クリック回数。
struct WeeklyClickData {
    private static let dayCount = 7

    let currentWeek: [DailyClickCount]
    let previousWeek: [DailyClickCount]
    let totalClicks: ClickBreakdown

    init(
        calendar: Calendar = .current,
        referenceDate: Date = .now,
        clicksForDate: (Date) -> ClickBreakdown
    ) {
        var calendar = calendar
        calendar.firstWeekday = 1

        let startOfCurrentWeek = calendar.dateInterval(
            of: .weekOfYear,
            for: referenceDate
        )?.start ?? calendar.startOfDay(for: referenceDate)

        currentWeek = Self.clicks(
            startingAt: startOfCurrentWeek,
            calendar: calendar,
            clicksForDate: clicksForDate
        )
        totalClicks = currentWeek.map(\.clicks).reduce(ClickBreakdown(), +)

        guard let startOfPreviousWeek = calendar.date(
            byAdding: .day,
            value: -Self.dayCount,
            to: startOfCurrentWeek
        ) else {
            previousWeek = []
            return
        }

        previousWeek = Self.clicks(
            startingAt: startOfPreviousWeek,
            calendar: calendar,
            clicksForDate: clicksForDate
        )
    }

    private static func clicks(
        startingAt firstDay: Date,
        calendar: Calendar,
        clicksForDate: (Date) -> ClickBreakdown
    ) -> [DailyClickCount] {
        (0..<dayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
                return nil
            }

            return DailyClickCount(day: day, clicks: clicksForDate(day))
        }
    }
}
