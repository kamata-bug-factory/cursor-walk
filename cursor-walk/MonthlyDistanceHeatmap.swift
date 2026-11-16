//
//  MonthlyDistanceHeatmap.swift
//  cursor-walk
//

import SwiftUI

/// 1か月の日別移動距離をカレンダー形式の濃淡で表示する。
struct MonthlyDistanceHeatmap: View {
    private static let retainedMonthOffset = -12

    let dailyDistances: [DailyDistance]
    let currentDayPoints: Double
    @State private var displayedMonth: Date
    @State private var history: MonthlyDistanceHistory

    init(dailyDistances: [DailyDistance], currentDayPoints: Double) {
        let referenceDate = Date.now

        self.dailyDistances = dailyDistances
        self.currentDayPoints = currentDayPoints
        _displayedMonth = State(
            initialValue: Calendar.current.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
        )
        _history = State(
            initialValue: MonthlyDistanceHistory(
                dailyDistances: dailyDistances,
                referenceDate: referenceDate
            )
        )
    }

    var body: some View {
        let data = MonthlyDistanceData(
            month: displayedMonth,
            history: history,
            currentDayPoints: currentDayPoints
        )

        VStack(alignment: .leading, spacing: 12) {
            MonthlyHeatmapHeader(
                month: data.month,
                totalPoints: data.totalPoints,
                canMoveBackward: canMoveBackward,
                canMoveForward: canMoveForward,
                moveBackward: { moveMonth(by: -1) },
                moveForward: { moveMonth(by: 1) }
            )

            MonthlyHeatmapContent(days: data.days)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: latestRecordedDay) {
            history = MonthlyDistanceHistory(dailyDistances: dailyDistances)
        }
    }

    private var latestRecordedDay: Date? {
        dailyDistances.last.map { Calendar.current.startOfDay(for: $0.day) }
    }

    private var canMoveBackward: Bool {
        displayedMonth > earliestMonth
    }

    private var canMoveForward: Bool {
        displayedMonth < currentMonth
    }

    private var currentMonth: Date {
        Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    private var earliestMonth: Date {
        Calendar.current.date(
            byAdding: .month,
            value: Self.retainedMonthOffset,
            to: currentMonth
        ) ?? currentMonth
    }

    private func moveMonth(by value: Int) {
        guard let month = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }

        displayedMonth = min(max(month, earliestMonth), currentMonth)
    }
}

private struct MonthlyHeatmapHeader: View {
    private static let valueColumnWidth: CGFloat = 120
    private static let navigationButtonLength: CGFloat = 28

    let month: Date
    let totalPoints: Double
    let canMoveBackward: Bool
    let canMoveForward: Bool
    let moveBackward: () -> Void
    let moveForward: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: moveBackward) {
                Image(systemName: "chevron.left")
                    .frame(
                        width: Self.navigationButtonLength,
                        height: Self.navigationButtonLength
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canMoveBackward)
            .opacity(canMoveBackward ? 1 : 0)
            .frame(
                width: Self.navigationButtonLength,
                height: Self.navigationButtonLength
            )
            .accessibilityLabel("前の月")
            .accessibilityHidden(!canMoveBackward)

            VStack(alignment: .center, spacing: 2) {
                Text(DateDisplayFormatter.yearMonth(from: month))
                    .font(.headline)
                Text("合計 \(DistanceFormatter.formattedDistance(for: totalPoints))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: Self.valueColumnWidth, alignment: .center)

            Button(action: moveForward) {
                Image(systemName: "chevron.right")
                    .frame(
                        width: Self.navigationButtonLength,
                        height: Self.navigationButtonLength
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canMoveForward)
            .opacity(canMoveForward ? 1 : 0)
            .frame(
                width: Self.navigationButtonLength,
                height: Self.navigationButtonLength
            )
            .accessibilityLabel("次の月")
            .accessibilityHidden(!canMoveForward)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private enum MonthlyHeatmapLayout {
    static let cellLength: CGFloat = 26
    static let cellSpacing: CGFloat = 5
    static let calendarWidth = cellLength * 7 + cellSpacing * 6
    static let calendarHeight: CGFloat = 201
    static let tooltipVerticalOffset = -(cellLength + cellSpacing)
}

private struct MonthlyHeatmapContent: View {
    let days: [MonthlyDistanceDay]

    var body: some View {
        VStack(spacing: 12) {
            MonthlyHeatmapCalendar(days: days)
            MonthlyHeatmapLegend()
        }
        .frame(width: MonthlyHeatmapLayout.calendarWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct MonthlyHeatmapCalendar: View {
    private static let columns = Array(
        repeating: GridItem(
            .fixed(MonthlyHeatmapLayout.cellLength),
            spacing: MonthlyHeatmapLayout.cellSpacing
        ),
        count: 7
    )
    private static let weekdaySymbols: [String] = {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar.veryShortStandaloneWeekdaySymbols
    }()

    let days: [MonthlyDistanceDay]
    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: Self.columns, spacing: MonthlyHeatmapLayout.cellSpacing) {
                ForEach(Self.weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: MonthlyHeatmapLayout.cellLength)
                }
            }

            LazyVGrid(columns: Self.columns, spacing: MonthlyHeatmapLayout.cellSpacing) {
                ForEach(days) { day in
                    MonthlyHeatmapDayCell(
                        day: day
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: MonthlyHeatmapLayout.calendarHeight, alignment: .center)
    }
}

private struct MonthlyHeatmapDayCell: View {
    let day: MonthlyDistanceDay
    @State private var isHovered = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(fillColor)

            if day.isInDisplayedMonth {
                Text(day.date, format: .dateTime.day())
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(day.points > 0 ? .white : .secondary)
            }
        }
        .frame(
            width: MonthlyHeatmapLayout.cellLength,
            height: MonthlyHeatmapLayout.cellLength
        )
        .opacity(day.isInDisplayedMonth ? 1 : 0)
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active:
                isHovered = true
            case .ended:
                isHovered = false
            }
        }
        .overlay(alignment: .top) {
            if isHovered {
                MonthlyHeatmapTooltip(day: day)
                    .fixedSize()
                    .offset(y: MonthlyHeatmapLayout.tooltipVerticalOffset)
            }
        }
        .zIndex(isHovered ? 1 : 0)
        .allowsHitTesting(day.isInDisplayedMonth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.date.formatted(.dateTime.year().month().day().weekday()))
        .accessibilityValue(DistanceFormatter.formattedDistance(for: day.points))
        .accessibilityHidden(!day.isInDisplayedMonth)
    }

    private var fillColor: Color {
        guard day.intensityLevel > 0 else {
            return Color.secondary.opacity(0.12)
        }

        return Color.accentColor.opacity(0.22 + Double(day.intensityLevel) * 0.195)
    }

}

private struct MonthlyHeatmapTooltip: View {
    let day: MonthlyDistanceDay

    var body: some View {
        Text("\(DateDisplayFormatter.yearMonthDayWeekday(from: day.date)) \(DistanceFormatter.formattedDistance(for: day.points))")
            .font(.caption)
            .distanceTooltipStyle()
    }
}

private struct MonthlyHeatmapLegend: View {
    var body: some View {
        HStack(spacing: 5) {
            Spacer()
            Text("少ない")
            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(legendColor(for: level))
                    .frame(width: 12, height: 12)
            }
            Text("多い")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("移動距離の色。薄いほど少なく、濃いほど多い")
    }

    private func legendColor(for level: Int) -> Color {
        guard level > 0 else {
            return Color.secondary.opacity(0.12)
        }
        return Color.accentColor.opacity(0.22 + Double(level) * 0.195)
    }
}
