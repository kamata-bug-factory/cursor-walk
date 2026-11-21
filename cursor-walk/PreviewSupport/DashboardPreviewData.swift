import SwiftUI

private enum DashboardPreviewData {
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

    static var dailyScrollDistances: [DailyScrollDistance] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<30).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset - 29, to: today) else {
                return nil
            }
            return DailyScrollDistance(day: day, points: Double(8_000 + offset * 1_700))
        }
    }
}

private struct ContentViewPreview: View {
    @StateObject private var mouseTracker: MouseTracker
    @StateObject private var clickTracker: MouseClickTracker
    @StateObject private var scrollTracker: MouseScrollTracker
    private let selectedMetric: MeasurementMetric

    init(
        selectedMetric: MeasurementMetric,
        dailyDistances: [DailyDistance],
        dailyClicks: [DailyClickCount],
        dailyScrollDistances: [DailyScrollDistance] = DashboardPreviewData.dailyScrollDistances
    ) {
        self.selectedMetric = selectedMetric
        _mouseTracker = StateObject(
            wrappedValue: MouseTracker(previewDistances: dailyDistances)
        )
        _clickTracker = StateObject(
            wrappedValue: MouseClickTracker(previewClicks: dailyClicks)
        )
        _scrollTracker = StateObject(
            wrappedValue: MouseScrollTracker(previewDistances: dailyScrollDistances)
        )
    }

    var body: some View {
        ContentViewContent(
            mouseTracker: mouseTracker,
            clickTracker: clickTracker,
            scrollTracker: scrollTracker,
            selectedMetric: .constant(selectedMetric),
            isMetricSelectionEnabled: false,
            onClose: {}
        )
    }
}

#Preview("移動距離・記録あり") {
    ContentViewPreview(
        selectedMetric: .distance,
        dailyDistances: DashboardPreviewData.dailyDistances,
        dailyClicks: DashboardPreviewData.dailyClicks
    )
}

#Preview("クリック回数・記録あり") {
    ContentViewPreview(
        selectedMetric: .clicks,
        dailyDistances: DashboardPreviewData.dailyDistances,
        dailyClicks: DashboardPreviewData.dailyClicks
    )
}

#Preview("スクロール距離・記録あり") {
    ContentViewPreview(
        selectedMetric: .scrolls,
        dailyDistances: DashboardPreviewData.dailyDistances,
        dailyClicks: DashboardPreviewData.dailyClicks
    )
}

#Preview("移動距離・記録なし") {
    ContentViewPreview(
        selectedMetric: .distance,
        dailyDistances: [],
        dailyClicks: []
    )
}

#Preview("クリック回数・記録なし") {
    ContentViewPreview(
        selectedMetric: .clicks,
        dailyDistances: [],
        dailyClicks: []
    )
}

#Preview("スクロール距離・記録なし") {
    ContentViewPreview(
        selectedMetric: .scrolls,
        dailyDistances: [],
        dailyClicks: [],
        dailyScrollDistances: []
    )
}
