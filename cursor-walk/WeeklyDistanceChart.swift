//
//  WeeklyDistanceChart.swift
//  cursor-walk
//

import Charts
import SwiftUI

/// 直近7日間の移動距離を表示するグラフ。
struct WeeklyDistanceChart: View {
    let data: [DailyDistance]
    @State private var hoveredDistance: DailyDistance?

    private var distanceUnit: DistanceUnit {
        let maximumMeters = data.map { DistanceFormatter.meters(for: $0.points) }.max() ?? 0
        return maximumMeters >= 1_000 ? .kilometers : .meters
    }

    private var axisConfiguration: DistanceAxisConfiguration {
        let maximumValue = data
            .map { $0.points * distanceUnit.scale }
            .max() ?? 0
        return DistanceAxisConfiguration(maximumValue: maximumValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("過去7日間")
                .font(.headline)

            Chart(data) { distance in
                BarMark(
                    x: .value("日付", distance.day, unit: .day),
                    y: .value("移動距離", distance.points * distanceUnit.scale)
                )
                .foregroundStyle(
                    Calendar.current.isDateInToday(distance.day) ? Color.accentColor : Color.secondary
                )
                .cornerRadius(4)
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                updateHoveredDistance(
                                    at: location,
                                    proxy: proxy,
                                    geometry: geometry
                                )
                            case .ended:
                                hoveredDistance = nil
                            }
                        }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let hoveredDistance,
                       let barCenter = Calendar.current.date(
                        byAdding: .hour,
                        value: 12,
                        to: hoveredDistance.day
                       ),
                       let xPosition = proxy.position(forX: barCenter),
                       let plotAreaFrame = proxy.plotFrame {
                        let plotFrame = geometry[plotAreaFrame]

                        DistanceTooltip(distance: hoveredDistance)
                            .position(
                                x: plotFrame.origin.x + xPosition,
                                y: plotFrame.minY + 16
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
                            Text(date, format: .dateTime.month(.defaultDigits).day())
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
            .chartYAxisLabel("移動距離（\(distanceUnit.symbol)）", position: .top, alignment: .leading)
            .frame(height: 190)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// ポインタ位置に対応する日付を特定し、ツールチップの表示対象を更新する。
    ///
    /// - Parameters:
    ///   - location: チャート上のポインタ位置。
    ///   - proxy: 座標とデータ値を相互変換するチャートプロキシ。
    ///   - geometry: チャートのプロット領域を取得するためのジオメトリプロキシ。
    private func updateHoveredDistance(
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
            hoveredDistance = nil
            return
        }

        hoveredDistance = data.min {
            abs($0.day.timeIntervalSince(date)) < abs($1.day.timeIntervalSince(date))
        }
    }
}

/// 日別の移動距離を示すツールチップ。
private struct DistanceTooltip: View {
    let distance: DailyDistance

    var body: some View {
        VStack(spacing: 2) {
            Text(distance.day, format: .dateTime.month(.defaultDigits).day())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(DistanceFormatter.formattedDistance(for: distance.points))
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        .allowsHitTesting(false)
    }
}

/// データの最大値から、読みやすいY軸の上限と目盛りを求める。
private struct DistanceAxisConfiguration {
    let upperBound: Double
    let values: [Double]

    init(maximumValue: Double) {
        guard maximumValue > 0 else {
            upperBound = 100
            values = [0, 20, 40, 60, 80, 100]
            return
        }

        let targetIntervalCount = 5.0
        let step = Self.niceStep(for: maximumValue / targetIntervalCount)
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
            DistanceFormatter.metersPerPoint / 1_000
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
