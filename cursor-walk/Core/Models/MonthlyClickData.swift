//
//  MonthlyClickData.swift
//  cursor-walk
//

import Foundation

/// 本日以外の日別クリック記録と、色の強度を決める境界値。
struct MonthlyClickHistory {
    private static let minimumIntensityLevel = 1
    private static let maximumIntensityLevel = 4

    private let clicksByDay: [Date: ClickBreakdown]
    private let sortedPositiveTotals: [Int]

    init(
        dailyClicks: [DailyClickCount],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        clicksByDay = dailyClicks.reduce(into: [Date: ClickBreakdown]()) { result, record in
            let day = calendar.startOfDay(for: record.day)
            guard day != referenceDay else {
                return
            }
            result[day] = (result[day] ?? ClickBreakdown()) + record.clicks
        }

        sortedPositiveTotals = clicksByDay.values
            .map(\.total)
            .filter { $0 > 0 }
            .sorted()
    }

    func clicks(for day: Date, calendar: Calendar) -> ClickBreakdown {
        clicksByDay[calendar.startOfDay(for: day)] ?? ClickBreakdown()
    }

    func intensityLevel(for total: Int) -> Int {
        guard total > 0 else {
            return 0
        }
        guard !sortedPositiveTotals.isEmpty else {
            return Self.maximumIntensityLevel
        }

        let upperRank = (sortedPositiveTotals.lastIndex { $0 <= total } ?? -1) + 1
        let percentile = Double(upperRank) / Double(sortedPositiveTotals.count)
        let calculatedLevel = Int(ceil(percentile * Double(Self.maximumIntensityLevel)))
        return max(
            Self.minimumIntensityLevel,
            min(Self.maximumIntensityLevel, calculatedLevel)
        )
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
        var calendar = calendar
        calendar.firstWeekday = 1

        let monthStart = calendar.dateInterval(of: .month, for: month)?.start
            ?? calendar.startOfDay(for: month)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let leadingDayCount = (
            calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7
        ) % 7
        let cellCount = Int(ceil(Double(leadingDayCount + dayCount) / 7.0)) * 7

        let datedClicks: [(date: Date, clicks: ClickBreakdown, isInDisplayedMonth: Bool)] =
            (0..<cellCount).compactMap { offset in
                guard let date = calendar.date(
                    byAdding: .day,
                    value: offset - leadingDayCount,
                    to: monthStart
                ) else {
                    return nil
                }

                let day = calendar.startOfDay(for: date)
                let clicks = day == referenceDay
                    ? currentDayClicks
                    : history.clicks(for: day, calendar: calendar)
                return (
                    date: date,
                    clicks: clicks,
                    isInDisplayedMonth: calendar.isDate(
                        date,
                        equalTo: monthStart,
                        toGranularity: .month
                    )
                )
            }

        self.month = monthStart
        days = datedClicks.map { day in
            MonthlyClickDay(
                date: day.date,
                clicks: day.clicks,
                intensityLevel: history.intensityLevel(for: day.clicks.total),
                isInDisplayedMonth: day.isInDisplayedMonth
            )
        }
        totalClicks = datedClicks
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
}
