//
//  WeeklyClickChart.swift
//  cursor-walk
//

import Charts
import SwiftUI

/// 今週のボタン別クリック回数を積み上げ、前週の合計と比較するグラフ。
struct WeeklyClickChart: View {
    private static let chartHeight: CGFloat = 190
    private static let targetAxisIntervalCount = 5.0

    let currentWeek: [DailyClickCount]
    let previousWeek: [DailyClickCount]
    let totalClicks: ClickBreakdown
    @State private var hoveredClicks: DailyClickComparison?
    @State private var tooltipWidth: CGFloat = 0

    private var comparisonData: [DailyClickComparison] {
        zip(currentWeek, previousWeek).map { current, previous in
            DailyClickComparison(
                day: current.day,
                current: current.clicks,
                previousTotal: previous.clicks.total
            )
        }
    }

    private var chartMarks: [ClickChartMark] {
        comparisonData.flatMap { comparison in
            var marks = [
                ClickChartMark(
                    day: comparison.day,
                    series: .previous,
                    button: .previous,
                    count: comparison.previousTotal
                ),
                ClickChartMark(
                    day: comparison.day,
                    series: .current,
                    button: .left,
                    count: comparison.current.left
                ),
                ClickChartMark(
                    day: comparison.day,
                    series: .current,
                    button: .right,
                    count: comparison.current.right
                ),
                ClickChartMark(
                    day: comparison.day,
                    series: .current,
                    button: .middle,
                    count: comparison.current.middle
                )
            ]

            if comparison.current.other > 0 {
                marks.append(
                    ClickChartMark(
                        day: comparison.day,
                        series: .current,
                        button: .other,
                        count: comparison.current.other
                    )
                )
            }
            return marks
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
        VStack(alignment: .leading, spacing: 8) {
            WeeklyClickHeader(
                firstDay: currentWeek.first?.day,
                lastDay: currentWeek.last?.day,
                total: totalClicks.total
            )

            Chart(chartMarks) { mark in
                BarMark(
                    x: .value("日付", mark.day, unit: .day),
                    y: .value("クリック回数", mark.count)
                )
                .position(by: .value("週", mark.series.rawValue))
                .foregroundStyle(mark.button.color)
                .cornerRadius(mark.button == .previous ? 4 : 2)
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                updateHoveredClicks(
                                    at: location,
                                    proxy: proxy,
                                    geometry: geometry
                                )
                            case .ended:
                                hoveredClicks = nil
                            }
                        }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let hoveredClicks,
                       let barCenter = Calendar.current.date(
                        byAdding: .hour,
                        value: 12,
                        to: hoveredClicks.day
                       ),
                       let xPosition = proxy.position(forX: barCenter),
                       let plotAreaFrame = proxy.plotFrame {
                        let plotFrame = geometry[plotAreaFrame]
                        let rawXPosition = plotFrame.origin.x + xPosition
                        let tooltipHalfWidth = min(
                            tooltipWidth / 2,
                            plotFrame.width / 2
                        )
                        let tooltipXPosition = min(
                            max(rawXPosition, plotFrame.minX + tooltipHalfWidth),
                            plotFrame.maxX - tooltipHalfWidth
                        )

                        ClickChartTooltip(comparison: hoveredClicks)
                            .fixedSize()
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.width
                            } action: { width in
                                tooltipWidth = width
                            }
                            .position(
                                x: tooltipXPosition,
                                y: plotFrame.minY + ClickTooltipLayout.centerYOffset
                            )
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()

                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(DateDisplayFormatter.monthDayWeekday(from: date))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...axisConfiguration.upperBound)
            .chartYAxis {
                AxisMarks(values: axisConfiguration.values) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxisLabel("クリック回数", position: .top, alignment: .leading)
            .frame(height: Self.chartHeight)

            ClickChartLegend()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func updateHoveredClicks(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard
            let plotAreaFrame = proxy.plotFrame,
            geometry[plotAreaFrame].contains(location),
            let date = proxy.value(
                atX: location.x - geometry[plotAreaFrame].origin.x,
                as: Date.self
            )
        else {
            hoveredClicks = nil
            return
        }

        let calendar = Calendar.current
        hoveredClicks = comparisonData.first {
            calendar.isDate($0.day, inSameDayAs: date)
        }
    }
}

private enum ClickTooltipLayout {
    static let centerYOffset: CGFloat = 40
}

private struct WeeklyClickHeader: View {
    let firstDay: Date?
    let lastDay: Date?
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(weekRangeText)
                .font(.headline)
            Text("合計 \(ClickFormatter.countWithUnit(total))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var weekRangeText: String {
        guard let firstDay, let lastDay else {
            return "週間"
        }

        return "\(DateDisplayFormatter.monthDayWeekday(from: firstDay))〜\(DateDisplayFormatter.monthDayWeekday(from: lastDay))"
    }
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
        }
        .tooltipStyle()
    }
}

private struct DailyClickComparison: Identifiable {
    let day: Date
    let current: ClickBreakdown
    let previousTotal: Int

    var id: Date { day }
}

private struct ClickChartMark: Identifiable {
    let day: Date
    let series: ClickWeekSeries
    let button: ClickButtonSeries
    let count: Int

    var id: String {
        "\(day.timeIntervalSinceReferenceDate)-\(series.rawValue)-\(button.rawValue)"
    }
}

private enum ClickWeekSeries: String {
    case current = "今週"
    case previous = "先週"
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
