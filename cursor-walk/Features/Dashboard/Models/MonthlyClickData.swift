import Foundation

/// 本日以外の日別クリック記録と、色の強度を決める境界値。
struct MonthlyClickHistory {
    private let clicksByDay: [Date: ClickBreakdown]
    private let intensityScale: HeatmapIntensityScale<Int>

    init(
        dailyClicks: [DailyClickCount],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let clicksByDay = dailyClicks.reduce(into: [Date: ClickBreakdown]()) { result, record in
            let day = calendar.startOfDay(for: record.day)
            guard day != referenceDay else {
                return
            }
            result[day] = (result[day] ?? ClickBreakdown()) + record.clicks
        }

        self.clicksByDay = clicksByDay
        intensityScale = HeatmapIntensityScale(
            positiveValues: clicksByDay.values.map(\.total).filter { $0 > 0 }
        )
    }

    func clicks(for day: Date, calendar: Calendar) -> ClickBreakdown {
        clicksByDay[calendar.startOfDay(for: day)] ?? ClickBreakdown()
    }

    func intensityLevel(for total: Int) -> Int {
        intensityScale.level(for: total, hasValue: total > 0)
    }
}

struct MonthlyClickData {
    let month: Date
    let days: [MonthlyClickDay]
    let totalClicks: ClickBreakdown

    init(
        month: Date,
        history: MonthlyClickHistory,
        currentDayClicks: ClickBreakdown,
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let grid = MonthlyCalendarGrid(month: month, calendar: calendar)
        let referenceDay = calendar.startOfDay(for: referenceDate)

        self.month = grid.month
        days = grid.days.map { gridDay in
            let day = calendar.startOfDay(for: gridDay.date)
            let clicks = day == referenceDay
                ? currentDayClicks
                : history.clicks(for: day, calendar: calendar)

            return MonthlyClickDay(
                date: gridDay.date,
                clicks: clicks,
                intensityLevel: history.intensityLevel(for: clicks.total),
                isInDisplayedMonth: gridDay.isInDisplayedMonth
            )
        }
        totalClicks = days
            .filter(\.isInDisplayedMonth)
            .map(\.clicks)
            .reduce(ClickBreakdown(), +)
    }
}

struct MonthlyClickDay: Identifiable {
    let date: Date
    let clicks: ClickBreakdown
    let intensityLevel: Int
    let isInDisplayedMonth: Bool

    var id: Date { date }
    var hasValue: Bool { clicks.total > 0 }
}
