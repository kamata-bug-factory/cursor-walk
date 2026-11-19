//
//  MonthlyDistanceData.swift
//  cursor-walk
//

import Foundation

/// 本日以外の日別移動距離と、色の強度を決める境界値。
struct MonthlyDistanceHistory {
    private static let minimumIntensityLevel = 1
    private static let maximumIntensityLevel = 4

    private let pointsByDay: [Date: Double]
    private let sortedPositivePoints: [Double]

    init(
        dailyDistances: [DailyDistance],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        pointsByDay = dailyDistances.reduce(into: [Date: Double]()) { result, distance in
            let day = calendar.startOfDay(for: distance.day)
            guard day != referenceDay else {
                return
            }
            result[day, default: 0] += distance.points
        }

        sortedPositivePoints = pointsByDay.values
            .filter { $0 > 0 }
            .sorted()
    }

    func points(for day: Date, calendar: Calendar) -> Double {
        pointsByDay[calendar.startOfDay(for: day)] ?? 0
    }

    func intensityLevel(for points: Double) -> Int {
        guard points > 0 else {
            return 0
        }
        guard !sortedPositivePoints.isEmpty else {
            return Self.maximumIntensityLevel
        }

        let upperRank = (sortedPositivePoints.lastIndex { $0 <= points } ?? -1) + 1
        let percentile = Double(upperRank) / Double(sortedPositivePoints.count)
        let calculatedLevel = Int(ceil(percentile * Double(Self.maximumIntensityLevel)))
        return max(
            Self.minimumIntensityLevel,
            min(Self.maximumIntensityLevel, calculatedLevel)
        )
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
        var calendar = calendar
        calendar.firstWeekday = 1

        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? calendar.startOfDay(for: month)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let leadingDayCount = (
            calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7
        ) % 7
        let cellCount = Int(ceil(Double(leadingDayCount + dayCount) / 7.0)) * 7

        let datedPoints: [(date: Date, points: Double, isInDisplayedMonth: Bool)] = (0..<cellCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - leadingDayCount, to: monthStart) else {
                return nil
            }

            let day = calendar.startOfDay(for: date)
            let points = day == referenceDay
                ? currentDayPoints
                : history.points(for: day, calendar: calendar)
            return (
                date: date,
                points: points,
                isInDisplayedMonth: calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            )
        }

        self.month = monthStart
        days = datedPoints.map { day in
            MonthlyDistanceDay(
                date: day.date,
                points: day.points,
                intensityLevel: history.intensityLevel(for: day.points),
                isInDisplayedMonth: day.isInDisplayedMonth
            )
        }
        totalPoints = datedPoints
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
