//
//  ContentView.swift
//  cursor-walk
//

import SwiftUI

/// 計測指標を切り替えて履歴を確認するメイン画面。
struct ContentView: View {
    let mouseTracker: MouseTracker
    let clickTracker: MouseClickTracker
    let scrollTracker: MouseScrollTracker
    let onClose: () -> Void

    @AppStorage("selectedMeasurementMetric")
    private var selectedMetric = MeasurementMetric.distance

    var body: some View {
        ContentViewContent(
            mouseTracker: mouseTracker,
            clickTracker: clickTracker,
            scrollTracker: scrollTracker,
            selectedMetric: $selectedMetric,
            isMetricSelectionEnabled: true,
            onClose: onClose
        )
    }
}

struct ContentViewContent: View {
    let mouseTracker: MouseTracker
    let clickTracker: MouseClickTracker
    let scrollTracker: MouseScrollTracker
    @Binding var selectedMetric: MeasurementMetric
    let isMetricSelectionEnabled: Bool
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if selectedMetric == .distance {
                DistanceTabs(mouseTracker: mouseTracker)
            } else if selectedMetric == .clicks {
                ClickTabs(clickTracker: clickTracker)
            } else {
                ScrollTabs(scrollTracker: scrollTracker)
            }

            ContentFooter(
                selectedMetric: $selectedMetric,
                isMetricSelectionEnabled: isMetricSelectionEnabled,
                onClose: onClose
            )
        }
        .frame(width: 460)
        .padding()
    }
}

private struct ContentFooter: View {
    @Binding var selectedMetric: MeasurementMetric
    let isMetricSelectionEnabled: Bool
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
            .disabled(!isMetricSelectionEnabled)
            .accessibilityLabel("表示する指標")

            Spacer()

            Button("閉じる", action: onClose)
        }
    }
}

enum MeasurementMetric: String, CaseIterable, Identifiable {
    case distance
    case clicks
    case scrolls

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .distance:
            "移動距離"
        case .clicks:
            "クリック回数"
        case .scrolls:
            "スクロール操作量"
        }
    }
}

private struct ScrollTabs: View {
    @ObservedObject var scrollTracker: MouseScrollTracker

    var body: some View {
        let weeklyData = WeeklyScrollData(pointsForDate: scrollTracker.points(for:))

        TabView {
            ScrollSummary(date: .now, points: scrollTracker.todayPoints)
                .tabItem { Label("本日", systemImage: "computermouse.and.arrowtriangle_2_outward") }
            WeeklyScrollChart(
                currentWeek: weeklyData.currentWeek,
                previousWeek: weeklyData.previousWeek,
                totalPoints: weeklyData.totalPoints
            )
            .tabItem { Label("週間", systemImage: "chart.bar") }
            MonthlyScrollHeatmap(
                dailyDistances: scrollTracker.dailyDistances,
                currentDayPoints: scrollTracker.todayPoints
            )
            .tabItem { Label("月間", systemImage: "calendar") }
        }
        .frame(height: AppLayout.tabHeight)
        .overlay(alignment: .topTrailing) {
            if scrollTracker.hasStorageError {
                StorageErrorBadge()
            }
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
        .frame(height: AppLayout.tabHeight)
        .overlay(alignment: .topTrailing) {
            if mouseTracker.hasStorageError {
                StorageErrorBadge()
            }
        }
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
        .frame(height: AppLayout.tabHeight)
        .overlay(alignment: .topTrailing) {
            if clickTracker.hasStorageError {
                StorageErrorBadge()
            }
        }
    }
}

private struct StorageErrorBadge: View {
    var body: some View {
        Label("記録を保存できません", systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
            .accessibilityLabel("記録を保存できません")
    }
}

