//
//  DateDisplayFormatter.swift
//  cursor-walk
//

import Foundation

/// アプリ内の日付表示形式をまとめたユーティリティ。
enum DateDisplayFormatter {
    private static let japaneseLocale = Locale(identifier: "ja_JP")
    private static let monthDayWeekdayStyle = Date.FormatStyle()
        .month(.defaultDigits)
        .day()
        .weekday(.abbreviated)
        .locale(japaneseLocale)
    private static let weekdayStyle = Date.FormatStyle()
        .weekday(.abbreviated)
        .locale(japaneseLocale)

    static func yearMonth(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)/\(components.month ?? 0)"
    }

    static func monthDayWeekday(from date: Date) -> String {
        date.formatted(monthDayWeekdayStyle)
    }

    static func yearMonthDayWeekday(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let weekday = date.formatted(weekdayStyle)

        return "\(components.year ?? 0)/\(components.month ?? 0)/\(components.day ?? 0)(\(weekday))"
    }
}
