import Foundation

/// 日曜始まりの今週と前週の日付列。
struct WeeklyDateRange {
    private static let dayCount = 7

    let currentWeek: [Date]
    let previousWeek: [Date]

    init(
        calendar sourceCalendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        var calendar = sourceCalendar
        calendar.firstWeekday = 1

        let currentWeekStart = calendar.dateInterval(
            of: .weekOfYear,
            for: referenceDate
        )?.start ?? calendar.startOfDay(for: referenceDate)

        currentWeek = Self.dates(startingAt: currentWeekStart, calendar: calendar)

        guard let previousWeekStart = calendar.date(
            byAdding: .day,
            value: -Self.dayCount,
            to: currentWeekStart
        ) else {
            previousWeek = []
            return
        }

        previousWeek = Self.dates(startingAt: previousWeekStart, calendar: calendar)
    }

    private static func dates(startingAt firstDay: Date, calendar: Calendar) -> [Date] {
        (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstDay)
        }
    }
}
