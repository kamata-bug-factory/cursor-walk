import SwiftUI

struct MonthlyScrollHeatmap: View {
    let dailyInputs: [DailyScrollInput]
    let currentDayLineUnits: Double
    @State private var displayedMonth: Date
    @State private var history: MonthlyScrollHistory

    init(dailyInputs: [DailyScrollInput], currentDayLineUnits: Double) {
        let referenceDate = Date.now
        self.dailyInputs = dailyInputs
        self.currentDayLineUnits = currentDayLineUnits
        _displayedMonth = State(
            initialValue: Calendar.current.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
        )
        _history = State(
            initialValue: MonthlyScrollHistory(dailyInputs: dailyInputs, referenceDate: referenceDate)
        )
    }

    var body: some View {
        let data = MonthlyScrollData(
            month: displayedMonth,
            history: history,
            currentDayLineUnits: currentDayLineUnits
        )

        MonthlyHeatmap(
            month: data.month,
            days: data.days,
            date: \.date,
            intensityLevel: \.intensityLevel,
            isInDisplayedMonth: \.isInDisplayedMonth,
            hasValue: \.hasValue,
            totalText: "合計 \(ScrollRotationFormatter.formatted(lineUnits: data.totalLineUnits))",
            legendAccessibilityLabel: "推定スクロール回転数の色。薄いほど少なく、濃いほど多い",
            canMoveBackward: displayedMonth > earliestMonth,
            canMoveForward: displayedMonth < currentMonth,
            moveBackward: { moveMonth(by: -1) },
            moveForward: { moveMonth(by: 1) },
            accessibilityValue: { ScrollRotationFormatter.formatted(lineUnits: $0.lineUnits) }
        ) { day in
            Text("\(DateDisplayFormatter.yearMonthDayWeekday(from: day.date)) \(ScrollRotationFormatter.formatted(lineUnits: day.lineUnits))")
                .font(.caption)
                .tooltipStyle()
        }
        .onChange(of: latestRecordedDay) {
            history = MonthlyScrollHistory(dailyInputs: dailyInputs)
        }
    }

    private var latestRecordedDay: Date? {
        dailyInputs.last.map { Calendar.current.startOfDay(for: $0.day) }
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
