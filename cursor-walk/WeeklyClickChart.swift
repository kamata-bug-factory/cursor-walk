//
//  WeeklyClickChart.swift
//  cursor-walk
//

import Charts
import SwiftUI

/// 今週のボタン別クリック回数を積み上げ、前週の合計と比較するグラフ。
struct WeeklyClickChart: View {
    private static let targetAxisIntervalCount = 5.0

    let currentWeek: [DailyClickCount]
    let previousWeek: [DailyClickCount]
    let totalClicks: ClickBreakdown

    private var comparisonData: [DailyClickComparison] {
        zip(currentWeek, previousWeek).map { current, previous in
            DailyClickComparison(
                day: current.day,
                current: current.clicks,
                previousTotal: previous.clicks.total
            )
        }
    }

    private var axisConfiguration: ClickAxisConfiguration {
        let maximumValue = comparisonData
            .flatMap { [$0.current.total, $0.previousTotal] }
            .max() ?? 0
        return ClickAxisConfiguration(
            maximumValue: maximumValue,
            targetIntervalCount: Self.targetAxisIntervalCount
        )
    }

    var body: some View {
        WeeklyComparisonChart(
            data: comparisonData,
            day: \.day,
            currentValue: \.currentValue,
            previousValue: \.previousValue,
            currentStyle: \.currentStyle,
            previousStyle: AnyShapeStyle(ClickButtonSeries.previous.color),
            totalText: "合計 \(ClickFormatter.countWithUnit(totalClicks.total))",
            valueName: "クリック回数",
            yAxisLabel: "クリック回数",
            yAxisUpperBound: Double(axisConfiguration.upperBound),
            yAxisValues: axisConfiguration.values.map(Double.init),
            tooltipCenterYOffset: ClickTooltipLayout.centerYOffset
        ) { comparison in
            ClickChartTooltip(comparison: comparison)
        } footer: {
            ClickChartLegend()
        }
    }
}

private enum ClickTooltipLayout {
    static let centerYOffset: CGFloat = 47
}

private struct ClickChartLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(ClickButtonSeries.legendCases) { button in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(button.color)
                        .frame(width: 10, height: 10)
                    Text(button.title)
                }
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}

private struct ClickChartTooltip: View {
    let comparison: DailyClickComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateDisplayFormatter.monthDayWeekday(from: comparison.day))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(ClickFormatter.countWithUnit(comparison.current.total))
                .font(.caption.weight(.semibold))
            Text(ClickFormatter.breakdown(comparison.current))
                .font(.caption2)
                .lineLimit(1)
            Text("先週 \(ClickFormatter.countWithUnit(comparison.previousTotal))")
                .font(.caption2)
            Text(comparisonText)
                .font(.caption2.weight(.semibold))
        }
        .tooltipStyle()
    }

    private var comparisonText: LocalizedStringResource {
        WeekComparisonFormatter.formatted(
            current: comparison.current.total,
            previous: comparison.previousTotal,
            on: comparison.day
        )
    }
}

private struct DailyClickComparison: Identifiable {
    let day: Date
    let current: ClickBreakdown
    let previousTotal: Int

    var id: Date { day }
    var currentValue: Double { Double(current.total) }
    var previousValue: Double { Double(previousTotal) }
    var currentStyle: AnyShapeStyle { AnyShapeStyle(currentBarStyle) }

    var currentBarStyle: LinearGradient {
        let segments: [(count: Int, color: Color)] = [
            (current.left, ClickButtonSeries.left.color),
            (current.right, ClickButtonSeries.right.color),
            (current.middle, ClickButtonSeries.middle.color),
            (current.other, ClickButtonSeries.other.color)
        ]
        let total = max(current.total, 1)
        var accumulatedCount = 0
        var stops: [Gradient.Stop] = []

        for segment in segments where segment.count > 0 {
            let start = Double(accumulatedCount) / Double(total)
            accumulatedCount += segment.count
            let end = Double(accumulatedCount) / Double(total)
            stops.append(Gradient.Stop(color: segment.color, location: start))
            stops.append(Gradient.Stop(color: segment.color, location: end))
        }

        if stops.isEmpty {
            stops = [
                Gradient.Stop(color: ClickButtonSeries.left.color, location: 0),
                Gradient.Stop(color: ClickButtonSeries.left.color, location: 1)
            ]
        }

        return LinearGradient(
            stops: stops,
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

private enum ClickButtonSeries: String, Identifiable {
    case left
    case right
    case middle
    case other
    case previous

    static let legendCases: [ClickButtonSeries] = [.left, .right, .middle, .other, .previous]

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .left: "左"
        case .right: "右"
        case .middle: "中"
        case .other: "その他"
        case .previous: "先週"
        }
    }

    var color: Color {
        switch self {
        case .left: .accentColor
        case .right: .orange
        case .middle: .purple
        case .other: .teal
        case .previous: .secondary.opacity(0.28)
        }
    }
}

private struct ClickAxisConfiguration {
    let upperBound: Int
    let values: [Int]

    init(maximumValue: Int, targetIntervalCount: Double) {
        guard maximumValue > 0 else {
            upperBound = 100
            values = [0, 20, 40, 60, 80, 100]
            return
        }

        let minimumStep = Double(maximumValue) / targetIntervalCount
        let step = Self.niceStep(for: minimumStep)
        let intervalCount = max(1, Int(ceil(Double(maximumValue) / Double(step))))

        upperBound = intervalCount * step
        values = (0...intervalCount).map { $0 * step }
    }

    private static func niceStep(for minimumStep: Double) -> Int {
        let magnitude = pow(10, floor(log10(max(minimumStep, 1))))
        let normalizedStep = minimumStep / magnitude

        let multiplier: Double
        switch normalizedStep {
        case ...1: multiplier = 1
        case ...2: multiplier = 2
        case ...5: multiplier = 5
        default: multiplier = 10
        }

        return max(1, Int(multiplier * magnitude))
    }
}
