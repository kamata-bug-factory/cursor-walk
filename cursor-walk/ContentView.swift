//
//  ContentView.swift
//  cursor-walk
//

import SwiftUI

/// 計測指標を切り替えて履歴を確認するメイン画面。
struct ContentView: View {
    let mouseTracker: MouseTracker
    let clickTracker: MouseClickTracker
    let onClose: () -> Void

    @AppStorage("selectedMeasurementMetric")
    private var selectedMetric = MeasurementMetric.distance

    var body: some View {
        VStack(spacing: 12) {
            if selectedMetric == .distance {
                DistanceTabs(mouseTracker: mouseTracker)
            } else {
                ClickTabs(clickTracker: clickTracker)
            }

            ContentFooter(
                selectedMetric: $selectedMetric,
                onClose: onClose
            )
        }
        .frame(width: 460)
        .padding()
    }
}

private struct ContentFooter: View {
    @Binding var selectedMetric: MeasurementMetric
    let onClose: () -> Void

    var body: some View {
        HStack {
            Picker("指標", selection: $selectedMetric) {
                ForEach(MeasurementMetric.allCases) { metric in
                    Text(metric.title)
                        .tag(metric)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .accessibilityLabel("表示する指標")

            Spacer()

            Button("閉じる", action: onClose)
        }
    }
}

private enum MeasurementMetric: String, CaseIterable, Identifiable {
    case distance
    case clicks

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .distance:
            "移動距離"
        case .clicks:
            "クリック回数"
        }
    }
}

private struct DistanceTabs: View {
    @ObservedObject var mouseTracker: MouseTracker

    var body: some View {
        let weeklyDistanceData = WeeklyDistanceData(pointsForDate: mouseTracker.points(for:))

        TabView {
            DistanceSummary(date: .now, points: mouseTracker.totalPoints)
                .tabItem {
                    Label("本日", systemImage: "cursorarrow.motionlines")
                }

            WeeklyDistanceChart(
                currentWeek: weeklyDistanceData.currentWeek,
                previousWeek: weeklyDistanceData.previousWeek,
                totalPoints: weeklyDistanceData.totalPoints
            )
            .tabItem {
                Label("週間", systemImage: "chart.bar")
            }

            MonthlyDistanceHeatmap(
                dailyDistances: mouseTracker.dailyDistances,
                currentDayPoints: mouseTracker.totalPoints
            )
            .tabItem {
                Label("月間", systemImage: "calendar")
            }
        }
        .frame(height: 330)
    }
}

private struct ClickTabs: View {
    @ObservedObject var clickTracker: MouseClickTracker

    var body: some View {
        let weeklyClickData = WeeklyClickData(clicksForDate: clickTracker.clicks(for:))

        TabView {
            ClickSummary(date: .now, clicks: clickTracker.todayClicks)
                .tabItem {
                    Label("本日", systemImage: "computermouse")
                }

            WeeklyClickChart(
                currentWeek: weeklyClickData.currentWeek,
                previousWeek: weeklyClickData.previousWeek,
                totalClicks: weeklyClickData.totalClicks
            )
            .tabItem {
                Label("週間", systemImage: "chart.bar")
            }

            MonthlyClickHeatmap(
                dailyClicks: clickTracker.dailyClicks,
                currentDayClicks: clickTracker.todayClicks
            )
            .tabItem {
                Label("月間", systemImage: "calendar")
            }
        }
        .frame(height: 330)
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

private enum PreviewData {
    static var dailyDistances: [DailyDistance] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let meters: [Double] = [
            180, 280, 900, 610, 320, 470, 1_200,
            120, 340, 1_250, 520, 260, 410, 1_800,
            750, 430, 980, 210, 1_460, 680, 390,
            1_050, 560, 270, 1_320, 840, 460, 1_600,
            720, 1_100
        ]

        return meters.enumerated().compactMap { offset, meters in
            guard let day = calendar.date(byAdding: .day, value: offset - 29, to: today) else {
                return nil
            }
            return DailyDistance(
                day: day,
                points: meters / DistanceFormatter.metersPerPoint
            )
        }
    }

    static var dailyClicks: [DailyClickCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<30).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset - 29, to: today) else {
                return nil
            }

            return DailyClickCount(
                day: day,
                clicks: ClickBreakdown(
                    left: 240 + offset * 13,
                    right: 30 + offset * 2,
                    middle: 8 + offset,
                    other: offset.isMultiple(of: 7) ? 3 : 0
                )
            )
        }
    }
}

#Preview("記録あり") {
    ContentView(
        mouseTracker: MouseTracker(previewDistances: PreviewData.dailyDistances),
        clickTracker: MouseClickTracker(previewClicks: PreviewData.dailyClicks),
        onClose: {}
    )
}

#Preview("記録なし") {
    ContentView(
        mouseTracker: MouseTracker(previewDistances: []),
        clickTracker: MouseClickTracker(previewClicks: []),
        onClose: {}
    )
}
