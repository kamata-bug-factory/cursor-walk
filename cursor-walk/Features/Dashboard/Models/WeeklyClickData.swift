import Foundation

/// 日曜始まりの今週と前週の日別クリック回数。
struct WeeklyClickData {
    let currentWeek: [DailyClickCount]
    let previousWeek: [DailyClickCount]
    let totalClicks: ClickBreakdown

    init(
        calendar: Calendar = .current,
        referenceDate: Date = .now,
        clicksForDate: (Date) -> ClickBreakdown
    ) {
        let dateRange = WeeklyDateRange(
            calendar: calendar,
            referenceDate: referenceDate
        )

        currentWeek = dateRange.currentWeek.map { day in
            DailyClickCount(day: day, clicks: clicksForDate(day))
        }
        previousWeek = dateRange.previousWeek.map { day in
            DailyClickCount(day: day, clicks: clicksForDate(day))
        }
        totalClicks = currentWeek.map(\.clicks).reduce(ClickBreakdown(), +)
    }
}
