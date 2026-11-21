import SwiftUI

struct MonthlyScrollHeatmap: View {
    let dailyDistances: [DailyScrollDistance]
    let currentDayPoints: Double
    @State private var displayedMonth: Date
    @State private var history: MonthlyScrollHistory

    init(dailyDistances: [DailyScrollDistance], currentDayPoints: Double) {
        let referenceDate = Date.now
        self.dailyDistances = dailyDistances
        self.currentDayPoints = currentDayPoints
        _displayedMonth = State(
            initialValue: Calendar.current.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
        )
        _history = State(
            initialValue: MonthlyScrollHistory(dailyDistances: dailyDistances, referenceDate: referenceDate)
        )
    }

    var body: some View {
        let data = MonthlyScrollData(
            month: displayedMonth,
            history: history,
            currentDayPoints: currentDayPoints
        )

        MonthlyHeatmap(
            month: data.month,
            days: data.days,
            date: \.date,
            intensityLevel: \.intensityLevel,
            isInDisplayedMonth: \.isInDisplayedMonth,
            hasValue: \.hasValue,
            totalText: "合計 \(ScrollFormatter.formattedDistance(for: data.totalPoints))",
            legendAccessibilityLabel: "スクロール距離の色。薄いほど短く、濃いほど長い",
            canMoveBackward: displayedMonth > earliestMonth,
            canMoveForward: displayedMonth < currentMonth,
            moveBackward: { moveMonth(by: -1) },
            moveForward: { moveMonth(by: 1) },
            accessibilityValue: { ScrollFormatter.formattedDistance(for: $0.points) }
        ) { day in
            Text("\(DateDisplayFormatter.yearMonthDayWeekday(from: day.date)) \(ScrollFormatter.formattedDistance(for: day.points))")
                .font(.caption)
                .tooltipStyle()
        }
        .onChange(of: latestRecordedDay) {
            history = MonthlyScrollHistory(dailyDistances: dailyDistances)
        }
    }

    private var latestRecordedDay: Date? {
        dailyDistances.last.map { Calendar.current.startOfDay(for: $0.day) }
    }
    private var currentMonth: Date {
        Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    }
    private var earliestMonth: Date {
        Calendar.current.date(
            byAdding: .month,
            value: MonthlyHeatmapStyle.retainedMonthOffset,
            to: currentMonth
        ) ?? currentMonth
    }

    private func moveMonth(by value: Int) {
        guard let month = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }
        displayedMonth = min(max(month, earliestMonth), currentMonth)
    }
}
