import Foundation

/// 本日以外の日別スクロール行相当量と、色の強度を決める境界値。
struct MonthlyScrollHistory {
    private let lineUnitsByDay: [Date: Double]
    private let intensityScale: HeatmapIntensityScale<Double>

    init(
        dailyInputs: [DailyScrollInput],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let lineUnitsByDay = dailyInputs.reduce(into: [Date: Double]()) { result, record in
            let day = calendar.startOfDay(for: record.day)
            guard day != referenceDay else {
                return
            }
            if result[day] == nil {
                result[day] = record.lineUnits
            }
        }

        self.lineUnitsByDay = lineUnitsByDay
        intensityScale = HeatmapIntensityScale(
            positiveValues: lineUnitsByDay.values.filter { $0 > 0 }
        )
    }

    func lineUnits(for day: Date, calendar: Calendar) -> Double {
        lineUnitsByDay[calendar.startOfDay(for: day)] ?? 0
    }

    func intensityLevel(for lineUnits: Double) -> Int {
        intensityScale.level(for: lineUnits, hasValue: lineUnits > 0)
    }
}

struct MonthlyScrollData {
    let month: Date
    let days: [MonthlyScrollDay]
    let totalLineUnits: Double

    init(
        month: Date,
        history: MonthlyScrollHistory,
        currentDayLineUnits: Double,
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let grid = MonthlyCalendarGrid(month: month, calendar: calendar)
        let referenceDay = calendar.startOfDay(for: referenceDate)

        self.month = grid.month
        days = grid.days.map { gridDay in
            let day = calendar.startOfDay(for: gridDay.date)
            let lineUnits = day == referenceDay
                ? currentDayLineUnits
                : history.lineUnits(for: day, calendar: calendar)

            return MonthlyScrollDay(
                date: gridDay.date,
                lineUnits: lineUnits,
                intensityLevel: history.intensityLevel(for: lineUnits),
                isInDisplayedMonth: gridDay.isInDisplayedMonth
            )
        }
        totalLineUnits = days
            .filter(\.isInDisplayedMonth)
            .map(\.lineUnits)
            .reduce(0, +)
    }
}

struct MonthlyScrollDay: Identifiable {
    let date: Date
    let lineUnits: Double
    let intensityLevel: Int
    let isInDisplayedMonth: Bool

    var id: Date { date }
    var hasValue: Bool { lineUnits > 0 }
}
