//
//  WeekComparisonFormatter.swift
//  cursor-walk
//

import Foundation

/// 今週の値と先週の値を比較し、先週比の表示形式へ変換するユーティリティ。
enum WeekComparisonFormatter {
    /// 整数値の先週比を、符号付きの百分率で返す。
    static func formatted(
        current: Int,
        previous: Int,
        on day: Date,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> LocalizedStringResource {
        formatted(
            current: Double(current),
            previous: Double(previous),
            on: day,
            calendar: calendar,
            now: now
        )
    }

    /// 小数値の先週比を、符号付きの百分率で返す。
    static func formatted(
        current: Double,
        previous: Double,
        on day: Date,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> LocalizedStringResource {
        let isFuture = calendar.compare(
            day,
            to: now,
            toGranularity: .day
        ) == .orderedDescending

        guard previous > 0, !isFuture else {
            return "先週比 -"
        }

        let percentage = Int(
            ((current - previous) / previous * 100)
                .rounded()
        )
        return "先週比 \(percentage, format: .number.sign(strategy: .always()))%"
    }
}
