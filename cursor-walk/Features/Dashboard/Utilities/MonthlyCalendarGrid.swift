import Foundation

/// 月間ヒートマップに表示する、前後月の余白を含む日付グリッド。
struct MonthlyCalendarGrid {
    struct Day {
        let date: Date
        let isInDisplayedMonth: Bool
    }

    let month: Date
    let days: [Day]

    init(
        month: Date,
        calendar sourceCalendar: Calendar = .current
    ) {
        var calendar = sourceCalendar
        calendar.firstWeekday = 1

        let monthStart = calendar.dateInterval(of: .month, for: month)?.start
            ?? calendar.startOfDay(for: month)
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let leadingDayCount = (
            calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7
        ) % 7
        let cellCount = Int(ceil(Double(leadingDayCount + dayCount) / 7.0)) * 7

        self.month = monthStart
        days = (0..<cellCount).compactMap { offset in
            guard let date = calendar.date(
                byAdding: .day,
                value: offset - leadingDayCount,
                to: monthStart
            ) else {
                return nil
            }

            return Day(
                date: date,
                isInDisplayedMonth: calendar.isDate(
                    date,
                    equalTo: monthStart,
                    toGranularity: .month
                )
            )
        }
    }
}
