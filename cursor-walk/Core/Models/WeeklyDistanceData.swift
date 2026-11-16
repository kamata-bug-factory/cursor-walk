//
//  WeeklyDistanceData.swift
//  cursor-walk
//

import Foundation

/// 日曜始まりの今週と前週の日別移動距離。
struct WeeklyDistanceData {
    private static let dayCount = 7

    let currentWeek: [DailyDistance]
    let previousWeek: [DailyDistance]

    init(
        calendar: Calendar = .current,
        referenceDate: Date = .now,
        pointsForDate: (Date) -> Double
    ) {
        var calendar = calendar
        calendar.firstWeekday = 1

        let startOfCurrentWeek = calendar.dateInterval(
            of: .weekOfYear,
            for: referenceDate
        )?.start ?? calendar.startOfDay(for: referenceDate)

        currentWeek = Self.distances(
            startingAt: startOfCurrentWeek,
            calendar: calendar,
            pointsForDate: pointsForDate
        )

        guard let startOfPreviousWeek = calendar.date(
            byAdding: .day,
            value: -Self.dayCount,
            to: startOfCurrentWeek
        ) else {
            previousWeek = []
            return
        }

        previousWeek = Self.distances(
            startingAt: startOfPreviousWeek,
            calendar: calendar,
            pointsForDate: pointsForDate
        )
    }

    private static func distances(
        startingAt firstDay: Date,
        calendar: Calendar,
        pointsForDate: (Date) -> Double
    ) -> [DailyDistance] {
        (0..<dayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
                return nil
            }

            return DailyDistance(day: day, points: pointsForDate(day))
        }
    }
}
