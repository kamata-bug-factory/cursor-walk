import Foundation

/// 日曜始まりの今週と前週の日別スクロール距離。
struct WeeklyScrollData {
    let currentWeek: [DailyScrollDistance]
    let previousWeek: [DailyScrollDistance]
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
            DailyScrollDistance(day: day, points: pointsForDate(day))
        }
        previousWeek = dateRange.previousWeek.map { day in
            DailyScrollDistance(day: day, points: pointsForDate(day))
        }
        totalPoints = currentWeek.map(\.points).reduce(0, +)
    }
}
