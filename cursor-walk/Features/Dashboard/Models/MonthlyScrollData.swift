import Foundation

/// 本日以外の日別スクロール操作量と、色の強度を決める境界値。
struct MonthlyScrollHistory {
    private let pointsByDay: [Date: Double]
    private let intensityScale: HeatmapIntensityScale<Double>

    init(
        dailyDistances: [DailyScrollInputDistance],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let pointsByDay = dailyDistances.reduce(into: [Date: Double]()) { result, record in
            let day = calendar.startOfDay(for: record.day)
            guard day != referenceDay else {
                return
            }
            result[day, default: 0] += record.points
        }

        self.pointsByDay = pointsByDay
        intensityScale = HeatmapIntensityScale(
            positiveValues: pointsByDay.values.filter { $0 > 0 }
        )
    }

    func points(for day: Date, calendar: Calendar) -> Double {
        pointsByDay[calendar.startOfDay(for: day)] ?? 0
    }

    func intensityLevel(for points: Double) -> Int {
        intensityScale.level(for: points, hasValue: points > 0)
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
        let grid = MonthlyCalendarGrid(month: month, calendar: calendar)
        let referenceDay = calendar.startOfDay(for: referenceDate)

        self.month = grid.month
        days = grid.days.map { gridDay in
            let day = calendar.startOfDay(for: gridDay.date)
            let points = day == referenceDay
                ? currentDayPoints
                : history.points(for: day, calendar: calendar)

            return MonthlyScrollDay(
                date: gridDay.date,
                points: points,
                intensityLevel: history.intensityLevel(for: points),
                isInDisplayedMonth: gridDay.isInDisplayedMonth
            )
        }
        totalPoints = days
            .filter(\.isInDisplayedMonth)
            .map(\.points)
            .reduce(0, +)
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
