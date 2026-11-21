import SwiftUI

struct WeeklyScrollChart: View {
    let currentWeek: [DailyScrollInputDistance]
    let previousWeek: [DailyScrollInputDistance]
    let totalPoints: Double

    private var comparisons: [DailyScrollComparison] {
        zip(currentWeek, previousWeek).map {
            DailyScrollComparison(
                day: $0.day,
                currentPoints: $0.points,
                previousPoints: $1.points,
                currentValue: $0.points,
                previousValue: $1.points
            )
        }
    }

    private var axis: DistanceAxisConfiguration {
        DistanceAxisConfiguration(
            maximumValue: comparisons.flatMap { [$0.currentValue, $0.previousValue] }.max() ?? 0
        )
    }

    var body: some View {
        WeeklyComparisonChart(
            data: comparisons,
            day: \.day,
            currentValue: \.currentValue,
            previousValue: \.previousValue,
            currentStyle: \.currentStyle,
            previousStyle: AnyShapeStyle(Color.secondary.opacity(0.32)),
            totalText: "合計 \(ScrollActivityFormatter.formatted(totalPoints))",
            valueName: "スクロール操作量",
            yAxisLabel: "スクロール操作量",
            yAxisUpperBound: axis.upperBound,
            yAxisValues: axis.values,
            tooltipCenterYOffset: 38
        ) { item in
            VStack(alignment: .leading, spacing: 2) {
                Text(DateDisplayFormatter.monthDayWeekday(from: item.day))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(ScrollActivityFormatter.formatted(item.currentPoints))
                    .font(.caption.weight(.semibold))
                Text("先週 \(ScrollActivityFormatter.formatted(item.previousPoints))")
                    .font(.caption2)
                Text(WeeklyComparisonFormatter.formatted(
                    current: item.currentPoints,
                    previous: item.previousPoints,
                    on: item.day
                ))
                    .font(.caption2.weight(.semibold))
            }
            .tooltipStyle()
        } footer: {
            EmptyView()
        }
    }
}

private struct DailyScrollComparison: Identifiable {
    let day: Date
    let currentPoints: Double
    let previousPoints: Double
    let currentValue: Double
    let previousValue: Double
    var id: Date { day }
    var currentStyle: AnyShapeStyle { AnyShapeStyle(Color.accentColor) }
}
