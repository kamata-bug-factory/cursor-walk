//
//  WeeklyDistanceChart.swift
//  cursor-walk
//

import Charts
import SwiftUI

/// 今週の移動距離を、前週と比較して日曜から土曜の順に表示するグラフ。
struct WeeklyDistanceChart: View {
    let currentWeek: [DailyDistance]
    let previousWeek: [DailyDistance]
    let totalPoints: Double

    private var comparisonData: [DailyDistanceComparison] {
        zip(currentWeek, previousWeek).map { current, previous in
            DailyDistanceComparison(
                day: current.day,
                currentPoints: current.points,
                previousPoints: previous.points,
                currentValue: current.points * distanceUnit.scale,
                previousValue: previous.points * distanceUnit.scale
            )
        }
    }

    private var distanceUnit: DistanceUnit {
        let maximumPoints = (currentWeek + previousWeek).map(\.points).max() ?? 0
        return DistanceFormatter.meters(for: maximumPoints) >= DistanceFormatter.metersPerKilometer
            ? .kilometers
            : .meters
    }

    private var axisConfiguration: DistanceAxisConfiguration {
        let maximumValue = (currentWeek + previousWeek)
            .map { $0.points * distanceUnit.scale }
            .max() ?? 0
        return DistanceAxisConfiguration(maximumValue: maximumValue)
    }

    var body: some View {
        WeeklyComparisonChart(
            data: comparisonData,
            day: \.day,
            currentValue: \.currentValue,
            previousValue: \.previousValue,
            currentStyle: \.currentStyle,
            previousStyle: AnyShapeStyle(Color.secondary.opacity(0.32)),
            totalText: "合計 \(DistanceFormatter.formattedDistance(for: totalPoints))",
            valueName: "移動距離",
            yAxisLabel: "移動距離（\(distanceUnit.symbol)）",
            yAxisUpperBound: axisConfiguration.upperBound,
            yAxisValues: axisConfiguration.values,
            tooltipCenterYOffset: 38
        ) { distance in
            DistanceTooltip(distance: distance)
        } footer: {
            EmptyView()
        }
    }
}

private struct DailyDistanceComparison: Identifiable {
    let day: Date
    let currentPoints: Double
    let previousPoints: Double
    let currentValue: Double
    let previousValue: Double

    var id: Date { day }
    var currentStyle: AnyShapeStyle { AnyShapeStyle(Color.accentColor) }
}

/// 日別の移動距離と先週比を示すツールチップ。
private struct DistanceTooltip: View {
    let distance: DailyDistanceComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateDisplayFormatter.monthDayWeekday(from: distance.day))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(DistanceFormatter.formattedDistance(for: distance.currentPoints))
                .font(.caption.weight(.semibold))

            Text("先週 \(DistanceFormatter.formattedDistance(for: distance.previousPoints))")
                .font(.caption2)

            Text(comparisonText)
                .font(.caption2.weight(.semibold))
        }
        .tooltipStyle()
    }

    private var comparisonText: LocalizedStringResource {
        WeekComparisonFormatter.formatted(
            current: distance.currentPoints,
            previous: distance.previousPoints,
            on: distance.day
        )
    }
}

/// データの最大値から、読みやすいY軸の上限と目盛りを求める。
private struct DistanceAxisConfiguration {
    private static let targetIntervalCount = 5.0

    let upperBound: Double
    let values: [Double]

    init(maximumValue: Double) {
        guard maximumValue > 0 else {
            upperBound = 100
            values = [0, 20, 40, 60, 80, 100]
            return
        }

        let step = Self.niceStep(for: maximumValue / Self.targetIntervalCount)
        let intervalCount = max(1, Int(ceil(maximumValue / step)))

        upperBound = Double(intervalCount) * step
        values = (0...intervalCount).map { Double($0) * step }
    }

    /// 1、2、2.5、5、10の系列から、必要量以上の最小の間隔を選ぶ。
    private static func niceStep(for minimumStep: Double) -> Double {
        let magnitude = pow(10, floor(log10(minimumStep)))
        let normalizedStep = minimumStep / magnitude

        let multiplier: Double
        switch normalizedStep {
        case ...1:
            multiplier = 1
        case ...2:
            multiplier = 2
        case ...2.5:
            multiplier = 2.5
        case ...5:
            multiplier = 5
        default:
            multiplier = 10
        }

        return multiplier * magnitude
    }
}

/// グラフで使用する距離の単位。
private enum DistanceUnit {
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
        case .meters:
            "m"
        case .kilometers:
            "km"
        }
    }
}
