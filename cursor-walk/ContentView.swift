//
//  ContentView.swift
//  cursor-walk
//

import Charts
import SwiftUI

struct ContentView: View {
    @StateObject private var mouseTracker = MouseTracker()

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 20) {
            DistanceSummary(points: mouseTracker.totalPoints)
            WeeklyDistanceChart(data: chartData)
        }
        .frame(width: 460, height: 360)
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

private struct DistanceSummary: View {
    let points: Double

    var body: some View {
        VStack(spacing: 6) {
            Text("今日の移動距離")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(formattedDistance(points: points))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("\(Int(points)) pts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WeeklyDistanceChart: View {
    let data: [DailyDistance]

    private var distanceUnit: DistanceUnit {
        let maximumMeters = data.map { $0.points * metersPerPoint }.max() ?? 0
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
}

private enum DistanceUnit {
    case meters
    case kilometers

    var scale: Double {
        switch self {
        case .meters:
            metersPerPoint
        case .kilometers:
            metersPerPoint / 1_000
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

private let metersPerPoint = 0.0254 / 72.0

private func formattedDistance(points: Double) -> String {
    let meters = points * metersPerPoint

    if meters >= 1_000 {
        return String(format: "%.2f km", meters / 1_000)
    }

    return String(format: "%.0f m", meters)
}

#Preview {
    ContentView()
}
