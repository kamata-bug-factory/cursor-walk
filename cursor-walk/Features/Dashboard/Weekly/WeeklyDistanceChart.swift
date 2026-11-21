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

    private var distanceUnit: DistanceChartUnit {
        let maximumPoints = (currentWeek + previousWeek).map(\.points).max() ?? 0
        return DistanceChartUnit(maximumPoints: maximumPoints)
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
        WeeklyComparisonFormatter.formatted(
            current: distance.currentPoints,
            previous: distance.previousPoints,
            on: distance.day
        )
    }
}
