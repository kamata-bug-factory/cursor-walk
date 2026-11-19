//
//  WeeklyComparisonChart.swift
//  cursor-walk
//

import Charts
import SwiftUI

/// 今週と先週の日別値を重ねて比較する、週間グラフの共通レイアウト。
struct WeeklyComparisonChart<Item, Tooltip, Footer>: View
where Item: Identifiable, Item.ID == Date, Tooltip: View, Footer: View {
    private static var chartHeight: CGFloat { 190 }
    private static var previousBarWidth: CGFloat { 28 }
    private static var currentBarWidth: CGFloat { 22 }
    private static var barCornerRadius: CGFloat { 4 }

    let data: [Item]
    let day: KeyPath<Item, Date>
    let currentValue: KeyPath<Item, Double>
    let previousValue: KeyPath<Item, Double>
    let currentStyle: KeyPath<Item, AnyShapeStyle>
    let previousStyle: AnyShapeStyle
    let totalText: String
    let valueName: String
    let yAxisLabel: String
    let yAxisUpperBound: Double
    let yAxisValues: [Double]
    let tooltipCenterYOffset: CGFloat
    @ViewBuilder let tooltip: (Item) -> Tooltip
    @ViewBuilder let footer: () -> Footer

    @State private var hoveredItem: Item?
    @State private var tooltipWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WeeklyComparisonChartHeader(
                firstDay: data.first?[keyPath: day],
                lastDay: data.last?[keyPath: day],
                totalText: totalText
            )

            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("日付", item[keyPath: day], unit: .day),
                        yStart: .value("先週の開始位置", 0),
                        yEnd: .value("先週の\(valueName)", item[keyPath: previousValue]),
                        width: .fixed(Self.previousBarWidth)
                    )
                    .foregroundStyle(previousStyle)
                    .cornerRadius(Self.barCornerRadius)
                }

                ForEach(data) { item in
                    BarMark(
                        x: .value("日付", item[keyPath: day], unit: .day),
                        yStart: .value("今週の開始位置", 0),
                        yEnd: .value("今週の\(valueName)", item[keyPath: currentValue]),
                        width: .fixed(Self.currentBarWidth)
                    )
                    .foregroundStyle(item[keyPath: currentStyle])
                    .cornerRadius(Self.barCornerRadius)
                }
            }
            .chartOverlay { proxy in
                WeeklyChartHoverOverlay(
                    proxy: proxy,
                    onHover: updateHoveredItem(at:proxy:geometry:)
                )
            }
            .chartOverlay { proxy in
                WeeklyChartTooltipOverlay(
                    proxy: proxy,
                    hoveredItem: hoveredItem,
                    day: day,
                    tooltipWidth: $tooltipWidth,
                    centerYOffset: tooltipCenterYOffset,
                    tooltip: tooltip
                )
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
            .chartYScale(domain: 0...yAxisUpperBound)
            .chartYAxis {
                AxisMarks(values: yAxisValues) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxisLabel(yAxisLabel, position: .top, alignment: .leading)
            .frame(height: Self.chartHeight)

            footer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func updateHoveredItem(
        at location: CGPoint?,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard
            let location,
            let plotAreaFrame = proxy.plotFrame,
            geometry[plotAreaFrame].contains(location),
            let date = proxy.value(
                atX: location.x - geometry[plotAreaFrame].origin.x,
                as: Date.self
            )
        else {
            hoveredItem = nil
            return
        }

        let calendar = Calendar.current
        hoveredItem = data.first {
            calendar.isDate($0[keyPath: day], inSameDayAs: date)
        }
    }
}

private struct WeeklyComparisonChartHeader: View {
    let firstDay: Date?
    let lastDay: Date?
    let totalText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(weekRangeText)
                .font(.headline)
            Text(totalText)
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

private struct WeeklyChartHoverOverlay: View {
    let proxy: ChartProxy
    let onHover: (CGPoint?, ChartProxy, GeometryProxy) -> Void

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        onHover(location, proxy, geometry)
                    case .ended:
                        onHover(nil, proxy, geometry)
                    }
                }
        }
    }
}

private struct WeeklyChartTooltipOverlay<Item, Tooltip>: View
where Tooltip: View {
    let proxy: ChartProxy
    let hoveredItem: Item?
    let day: KeyPath<Item, Date>
    @Binding var tooltipWidth: CGFloat
    let centerYOffset: CGFloat
    @ViewBuilder let tooltip: (Item) -> Tooltip

    var body: some View {
        GeometryReader { geometry in
            if let hoveredItem,
               let barCenter = Calendar.current.date(
                byAdding: .hour,
                value: 12,
                to: hoveredItem[keyPath: day]
               ),
               let xPosition = proxy.position(forX: barCenter),
               let plotAreaFrame = proxy.plotFrame {
                let plotFrame = geometry[plotAreaFrame]
                let rawXPosition = plotFrame.origin.x + xPosition
                let tooltipHalfWidth = min(tooltipWidth / 2, plotFrame.width / 2)
                let tooltipXPosition = min(
                    max(rawXPosition, plotFrame.minX + tooltipHalfWidth),
                    plotFrame.maxX - tooltipHalfWidth
                )

                tooltip(hoveredItem)
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { width in
                        tooltipWidth = width
                    }
                    .position(
                        x: tooltipXPosition,
                        y: plotFrame.minY + centerYOffset
                    )
            }
        }
    }
}
