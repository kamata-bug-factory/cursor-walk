import Foundation

/// 日曜始まりの今週と前週の日別スクロール操作量。
struct WeeklyScrollData {
    let currentWeek: [DailyScrollInputDistance]
    let previousWeek: [DailyScrollInputDistance]
    let totalPoints: Double

    init(
        calendar: Calendar = .current,
        referenceDate: Date = .now,
        pointsForDate: (Date) -> Double
    ) {
        let dateRange = WeeklyDateRange(
            calendar: calendar,
            referenceDate: referenceDate
        )

        currentWeek = dateRange.currentWeek.map { day in
            DailyScrollInputDistance(day: day, points: pointsForDate(day))
        }
        previousWeek = dateRange.previousWeek.map { day in
            DailyScrollInputDistance(day: day, points: pointsForDate(day))
        }
        totalPoints = currentWeek.map(\.points).reduce(0, +)
    }
}
