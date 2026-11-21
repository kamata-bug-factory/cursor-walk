import Foundation

struct WeeklyScrollData {
    private static let dayCount = 7

    let currentWeek: [DailyScrollDistance]
    let previousWeek: [DailyScrollDistance]
    let totalPoints: Double

    init(
        calendar: Calendar = .current,
        referenceDate: Date = .now,
        pointsForDate: (Date) -> Double
    ) {
        var calendar = calendar
        calendar.firstWeekday = 1
        let start = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start
            ?? calendar.startOfDay(for: referenceDate)
        currentWeek = Self.scrolls(startingAt: start, calendar: calendar, pointsForDate: pointsForDate)
        totalPoints = currentWeek.map(\.points).reduce(0, +)
        guard let previousStart = calendar.date(byAdding: .day, value: -Self.dayCount, to: start) else {
            previousWeek = []
            return
        }
        previousWeek = Self.scrolls(
            startingAt: previousStart,
            calendar: calendar,
            pointsForDate: pointsForDate
        )
    }

    private static func scrolls(
        startingAt firstDay: Date,
        calendar: Calendar,
        pointsForDate: (Date) -> Double
    ) -> [DailyScrollDistance] {
        (0..<dayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else { return nil }
            return DailyScrollDistance(day: day, points: pointsForDate(day))
        }
    }
}
