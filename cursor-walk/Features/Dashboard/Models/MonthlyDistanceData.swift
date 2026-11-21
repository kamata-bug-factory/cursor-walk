import Foundation

/// 本日以外の日別移動距離と、色の強度を決める境界値。
struct MonthlyDistanceHistory {
    private let pointsByDay: [Date: Double]
    private let intensityScale: HeatmapIntensityScale<Double>

    init(
        dailyDistances: [DailyDistance],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let pointsByDay = dailyDistances.reduce(into: [Date: Double]()) { result, distance in
            let day = calendar.startOfDay(for: distance.day)
            guard day != referenceDay else {
                return
            }
            if result[day] == nil {
                result[day] = distance.points
            }
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

/// 1か月分の表示日と移動距離をまとめたデータ。
struct MonthlyDistanceData {
    let month: Date
    let days: [MonthlyDistanceDay]
    let totalPoints: Double

    init(
        month: Date,
        history: MonthlyDistanceHistory,
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

            return MonthlyDistanceDay(
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

/// 月間ヒートマップの1日分の表示データ。
struct MonthlyDistanceDay: Identifiable {
    let date: Date
    let points: Double
    let intensityLevel: Int
    let isInDisplayedMonth: Bool

    var id: Date { date }
    var hasValue: Bool { points > 0 }
}
