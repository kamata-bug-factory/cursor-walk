//
//  ContentView.swift
//  cursor-walk
//

import SwiftUI

/// 移動距離を確認するメイン画面。
struct ContentView: View {
    @ObservedObject var mouseTracker: MouseTracker
    let onClose: () -> Void

    var body: some View {
        let weeklyDistanceData = WeeklyDistanceData(pointsForDate: mouseTracker.points(for:))

        VStack(spacing: 12) {
            TabView {
                DistanceSummary(date: .now, points: mouseTracker.totalPoints)
                    .tabItem {
                        Label("本日", systemImage: "cursorarrow.motionlines")
                    }

                WeeklyDistanceChart(
                    currentWeek: weeklyDistanceData.currentWeek,
                    previousWeek: weeklyDistanceData.previousWeek
                )
                    .tabItem {
                        Label("週間", systemImage: "chart.bar")
                    }

                MonthlyDistanceHeatmap(dailyDistances: mouseTracker.dailyDistances)
                    .tabItem {
                        Label("月間", systemImage: "calendar")
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
}

/// 本日の移動距離を表示するビュー。
private struct DistanceSummary: View {
    private static let dateStyle = Date.FormatStyle()
        .month(.defaultDigits)
        .day()
        .weekday(.abbreviated)
        .locale(Locale(identifier: "ja_JP"))

    let date: Date
    let points: Double

    var body: some View {
        let formattedDate = date.formatted(Self.dateStyle)

        VStack(spacing: 6) {
            Text("\(formattedDate)の移動距離")
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
        let meters: [Double] = [
            180, 280, 900, 610, 320, 470, 1_200,
            120, 340, 1_250, 520, 260, 410, 1_800
        ]

        return meters.enumerated().compactMap { offset, meters in
            guard let day = calendar.date(byAdding: .day, value: offset - 13, to: today) else {
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
