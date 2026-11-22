import SwiftUI

struct WeeklyScrollChart: View {
    let currentWeek: [DailyScrollInput]
    let previousWeek: [DailyScrollInput]
    let totalLineUnits: Double

    private var comparisons: [DailyScrollComparison] {
        zip(currentWeek, previousWeek).map {
            DailyScrollComparison(
                day: $0.day,
                currentRotations: ScrollRotationFormatter.rotations(from: $0.lineUnits),
                previousRotations: ScrollRotationFormatter.rotations(from: $1.lineUnits),
                currentValue: ScrollRotationFormatter.rotations(from: $0.lineUnits),
                previousValue: ScrollRotationFormatter.rotations(from: $1.lineUnits)
            )
        }
    }

    private var axis: DistanceAxisConfiguration {
        let maximumValue = comparisons.flatMap { [$0.currentValue, $0.previousValue] }.max() ?? 0
        return DistanceAxisConfiguration(maximumValue: max(maximumValue, 1))
    }

    var body: some View {
        WeeklyComparisonChart(
            data: comparisons,
            day: \.day,
            currentValue: \.currentValue,
            previousValue: \.previousValue,
            currentStyle: \.currentStyle,
            previousStyle: AnyShapeStyle(Color.secondary.opacity(0.32)),
            totalText: "合計 \(ScrollRotationFormatter.formatted(lineUnits: totalLineUnits))",
            valueName: "推定スクロール回転数",
            yAxisLabel: "推定スクロール回転数（回）",
            yAxisUpperBound: axis.upperBound,
            yAxisValues: axis.values,
            tooltipCenterYOffset: 38
        ) { item in
            VStack(alignment: .leading, spacing: 2) {
                Text(DateDisplayFormatter.monthDayWeekday(from: item.day))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(item.currentRotations.formatted(.number.precision(.fractionLength(2))))回転")
                    .font(.caption.weight(.semibold))
                Text("先週 \(item.previousRotations.formatted(.number.precision(.fractionLength(2))))回転")
                    .font(.caption2)
                Text(WeeklyComparisonFormatter.formatted(
                    current: item.currentRotations,
                    previous: item.previousRotations,
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
    let currentRotations: Double
    let previousRotations: Double
    let currentValue: Double
    let previousValue: Double
    var id: Date { day }
    var currentStyle: AnyShapeStyle { AnyShapeStyle(Color.accentColor) }
}
