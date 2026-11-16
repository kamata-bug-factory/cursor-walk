//
//  MonthlyDistanceData.swift
//  cursor-walk
//

import Foundation

/// 1か月分の表示日と移動距離をまとめたデータ。
struct MonthlyDistanceData {
    let month: Date
    let days: [MonthlyDistanceDay]
    let totalPoints: Double

    init(month: Date, dailyDistances: [DailyDistance], calendar: Calendar = .current) {
        var calendar = calendar
        calendar.firstWeekday = 1

        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? calendar.startOfDay(for: month)
        let pointsByDay = dailyDistances.reduce(into: [Date: Double]()) { result, distance in
            result[calendar.startOfDay(for: distance.day), default: 0] += distance.points
        }
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let leadingDayCount = (
            calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7
        ) % 7
        let cellCount = Int(ceil(Double(leadingDayCount + dayCount) / 7.0)) * 7

        let datedPoints: [(date: Date, points: Double, isInDisplayedMonth: Bool)] = (0..<cellCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - leadingDayCount, to: monthStart) else {
                return nil
            }
            return (
                date: date,
                points: pointsByDay[date] ?? 0,
                isInDisplayedMonth: calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            )
        }
        let positivePointsInRetentionRange = pointsByDay.values
            .filter { $0 > 0 }
            .sorted()

        self.month = monthStart
        days = datedPoints.map { day in
            MonthlyDistanceDay(
                date: day.date,
                points: day.points,
                intensityLevel: Self.intensityLevel(
                    for: day.points,
                    among: positivePointsInRetentionRange
                ),
                isInDisplayedMonth: day.isInDisplayedMonth
            )
        }
        totalPoints = datedPoints
            .filter(\.isInDisplayedMonth)
            .map(\.points)
            .reduce(0, +)
    }

    private static func intensityLevel(for points: Double, among sortedPositivePoints: [Double]) -> Int {
        guard points > 0, !sortedPositivePoints.isEmpty else {
            return 0
        }

        let upperRank = (sortedPositivePoints.lastIndex { $0 <= points } ?? -1) + 1
        let percentile = Double(upperRank) / Double(sortedPositivePoints.count)
        return min(4, Int(ceil(percentile * 4)))
    }
}

/// 月間ヒートマップの1日分の表示データ。
struct MonthlyDistanceDay: Identifiable {
    let date: Date
    let points: Double
    let intensityLevel: Int
    let isInDisplayedMonth: Bool

    var id: Date { date }
}
