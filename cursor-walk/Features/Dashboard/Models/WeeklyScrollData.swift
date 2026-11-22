import Foundation

/// 日曜始まりの今週と前週の日別推定スクロール回転数。
struct WeeklyScrollData {
    let currentWeek: [DailyScrollInput]
    let previousWeek: [DailyScrollInput]
    let totalLineUnits: Double

    init(
        calendar: Calendar = .current,
        referenceDate: Date = .now,
        lineUnitsForDate: (Date) -> Double
    ) {
        let dateRange = WeeklyDateRange(
            calendar: calendar,
            referenceDate: referenceDate
        )

        currentWeek = dateRange.currentWeek.map { day in
            DailyScrollInput(day: day, lineUnits: lineUnitsForDate(day))
        }
        previousWeek = dateRange.previousWeek.map { day in
            DailyScrollInput(day: day, lineUnits: lineUnitsForDate(day))
        }
        totalLineUnits = currentWeek.map(\.lineUnits).reduce(0, +)
    }
}
