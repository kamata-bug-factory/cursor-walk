//
//  ContentView.swift
//  cursor-walk
//

import SwiftUI

/// 移動距離を確認するメイン画面。
struct ContentView: View {
    private static let chartDisplayDays = 7

    @ObservedObject var mouseTracker: MouseTracker
    let onClose: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
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

            HStack {
                Spacer()
                Button("閉じる", action: onClose)
            }
        }
        .frame(width: 460)
        .padding()
    }

    private var chartData: [DailyDistance] {
        guard let firstDay = calendar.date(
            byAdding: .day,
            value: -(Self.chartDisplayDays - 1),
            to: calendar.startOfDay(for: .now)
        ) else {
            return []
        }

        return (0..<Self.chartDisplayDays).compactMap { offset in
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


/// プレビューに表示するサンプル記録。
private enum PreviewData {
    static var dailyDistances: [DailyDistance] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let meters: [Double] = [120, 340, 1_250, 520, 260, 410, 1_800]

        return meters.enumerated().compactMap { offset, meters in
            guard let day = calendar.date(byAdding: .day, value: offset - 6, to: today) else {
                return nil
            }
            return DailyDistance(
                day: day,
                points: meters / DistanceFormatter.metersPerPoint
            )
        }
    }
}

#Preview("記録あり") {
    ContentView(
        mouseTracker: MouseTracker(previewDistances: PreviewData.dailyDistances),
        onClose: {}
    )
}

#Preview("記録なし") {
    ContentView(
        mouseTracker: MouseTracker(previewDistances: []),
        onClose: {}
    )
}
