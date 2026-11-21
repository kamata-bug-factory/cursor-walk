import Foundation

struct MonthlyScrollHistory {
    private let pointsByDay: [Date: Double]
    private let sortedPositiveValues: [Double]

    init(dailyDistances: [DailyScrollDistance], calendar: Calendar = .current, referenceDate: Date = .now) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        pointsByDay = dailyDistances.reduce(into: [Date: Double]()) { result, record in
            let day = calendar.startOfDay(for: record.day)
            guard day != referenceDay else { return }
            result[day, default: 0] += record.points
        }
        sortedPositiveValues = pointsByDay.values.filter { $0 > 0 }.sorted()
    }

    func points(for day: Date, calendar: Calendar) -> Double {
        pointsByDay[calendar.startOfDay(for: day)] ?? 0
    }

    func intensityLevel(for value: Double) -> Int {
        guard value > 0 else { return 0 }
        guard !sortedPositiveValues.isEmpty else { return 4 }
        let rank = (sortedPositiveValues.lastIndex { $0 <= value } ?? -1) + 1
        return max(1, min(4, Int(ceil(Double(rank) / Double(sortedPositiveValues.count) * 4))))
    }
}

struct MonthlyScrollData {
    let month: Date
    let days: [MonthlyScrollDay]
    let totalPoints: Double

    init(
        month: Date,
        history: MonthlyScrollHistory,
        currentDayPoints: Double,
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        var calendar = calendar
        calendar.firstWeekday = 1
        let monthStart = calendar.dateInterval(of: .month, for: month)?.start
            ?? calendar.startOfDay(for: month)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let cellCount = Int(ceil(Double(leading + dayCount) / 7)) * 7

        let values: [(Date, Double, Bool)] = (0..<cellCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - leading, to: monthStart) else {
                return nil
            }
            let day = calendar.startOfDay(for: date)
            let points = day == referenceDay
                ? currentDayPoints
                : history.points(for: day, calendar: calendar)
            let isInMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            return (date, points, isInMonth)
        }

        self.month = monthStart
        days = values.map {
            MonthlyScrollDay(
                date: $0.0,
                points: $0.1,
                intensityLevel: history.intensityLevel(for: $0.1),
                isInDisplayedMonth: $0.2
            )
        }
        totalPoints = values.filter(\.2).map(\.1).reduce(0, +)
    }
}

struct MonthlyScrollDay: Identifiable {
    let date: Date
    let points: Double
    let intensityLevel: Int
    let isInDisplayedMonth: Bool

    var id: Date { date }
    var hasValue: Bool { points > 0 }
}
