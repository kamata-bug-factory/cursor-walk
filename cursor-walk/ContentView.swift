//
//  ContentView.swift
//  cursor-walk
//

import Charts
import SwiftUI

/// 移動距離を確認するメイン画面。
struct ContentView: View {
    @ObservedObject var mouseTracker: MouseTracker

    private let calendar = Calendar.current

    var body: some View {
        TabView {
            DistanceSummary(points: mouseTracker.totalPoints)
                .tabItem {
                    Label("今日", systemImage: "cursorarrow.motionlines")
                }

            WeeklyDistanceChart(data: chartData)
                .tabItem {
                    Label("過去7日間", systemImage: "chart.bar")
                }
        }
        .frame(width: 460)
        .padding()
    }

    private var chartData: [DailyDistance] {
        guard let firstDay = calendar.date(
            byAdding: .day,
            value: -6,
            to: calendar.startOfDay(for: .now)
        ) else {
            return []
        }

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
                return nil
            }

            return DailyDistance(
                day: day,
                points: mouseTracker.points(for: day)
            )
        }
    }
}

/// 今日の移動距離を表示するビュー。
private struct DistanceSummary: View {
    let points: Double

    var body: some View {
        VStack(spacing: 6) {
            Text("今日の移動距離")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(DistanceFormatter.formattedDistance(for: points))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 8) {
                if DistanceFormatter.meters(for: points) >= 1_000 {
                    Text(DistanceFormatter.formattedMeters(for: points))
                }

                Text("\(Int(points)) pts")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 直近7日間の移動距離を表示するグラフ。
private struct WeeklyDistanceChart: View {
    let data: [DailyDistance]
    @State private var hoveredDistance: DailyDistance?

    private var distanceUnit: DistanceUnit {
        let maximumMeters = data.map { DistanceFormatter.meters(for: $0.points) }.max() ?? 0
        return maximumMeters >= 1_000 ? .kilometers : .meters
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
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) {
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

#Preview {
    ContentView(mouseTracker: MouseTracker())
}
