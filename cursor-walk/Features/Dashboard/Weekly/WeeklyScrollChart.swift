import SwiftUI

struct WeeklyScrollChart: View {
    let currentWeek: [DailyScrollDistance]
    let previousWeek: [DailyScrollDistance]
    let totalPoints: Double

    private var comparisons: [DailyScrollComparison] {
        zip(currentWeek, previousWeek).map {
            DailyScrollComparison(
                day: $0.day,
                currentPoints: $0.points,
                previousPoints: $1.points,
                currentValue: $0.points * distanceUnit.scale,
                previousValue: $1.points * distanceUnit.scale
            )
        }
    }

    private var distanceUnit: ScrollDistanceUnit {
        let maximumPoints = (currentWeek + previousWeek).map(\.points).max() ?? 0
        return DistanceFormatter.meters(for: maximumPoints) >= DistanceFormatter.metersPerKilometer
            ? .kilometers
            : .meters
    }

    private var axis: ScrollAxisConfiguration {
        ScrollAxisConfiguration(
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
            totalText: "合計 \(ScrollFormatter.formattedDistance(for: totalPoints))",
            valueName: "スクロール距離",
            yAxisLabel: "スクロール距離（\(distanceUnit.symbol)）",
            yAxisUpperBound: axis.upperBound,
            yAxisValues: axis.values,
            tooltipCenterYOffset: 38
        ) { item in
            VStack(alignment: .leading, spacing: 2) {
                Text(DateDisplayFormatter.monthDayWeekday(from: item.day))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(ScrollFormatter.formattedDistance(for: item.currentPoints))
                    .font(.caption.weight(.semibold))
                Text("先週 \(ScrollFormatter.formattedDistance(for: item.previousPoints))")
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

private enum ScrollDistanceUnit {
    case meters
    case kilometers

    var scale: Double {
        switch self {
        case .meters:
            DistanceFormatter.metersPerPoint
        case .kilometers:
            DistanceFormatter.metersPerPoint / DistanceFormatter.metersPerKilometer
        }
    }

    var symbol: String {
        switch self {
        case .meters: "m"
        case .kilometers: "km"
        }
    }
}

private struct ScrollAxisConfiguration {
    let upperBound: Double
    let values: [Double]

    init(maximumValue: Double) {
        guard maximumValue > 0 else {
            upperBound = 100
            values = [0, 20, 40, 60, 80, 100]
            return
        }
        let magnitude = pow(10, floor(log10(max(maximumValue / 5, 1))))
        let normalized = maximumValue / 5 / magnitude
        let multiplier: Double = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10
        let step = multiplier * magnitude
        let count = max(1, Int(ceil(maximumValue / step)))
        upperBound = Double(count) * step
        values = (0...count).map { Double($0) * step }
    }
}
