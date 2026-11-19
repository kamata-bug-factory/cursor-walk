//
//  MonthlyHeatmap.swift
//  cursor-walk
//

import SwiftUI

/// 日別データをカレンダー形式の濃淡で表示する、月間ヒートマップの共通レイアウト。
struct MonthlyHeatmap<Item, Tooltip>: View
where Item: Identifiable, Item.ID == Date, Tooltip: View {
    let month: Date
    let days: [Item]
    let date: KeyPath<Item, Date>
    let intensityLevel: KeyPath<Item, Int>
    let isInDisplayedMonth: KeyPath<Item, Bool>
    let hasValue: KeyPath<Item, Bool>
    let totalText: String
    let legendAccessibilityLabel: LocalizedStringResource
    let canMoveBackward: Bool
    let canMoveForward: Bool
    let moveBackward: () -> Void
    let moveForward: () -> Void
    let accessibilityValue: (Item) -> String
    @ViewBuilder let tooltip: (Item) -> Tooltip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MonthlyHeatmapHeader(
                month: month,
                totalText: totalText,
                canMoveBackward: canMoveBackward,
                canMoveForward: canMoveForward,
                moveBackward: moveBackward,
                moveForward: moveForward
            )

            MonthlyHeatmapContent(
                days: days,
                date: date,
                intensityLevel: intensityLevel,
                isInDisplayedMonth: isInDisplayedMonth,
                hasValue: hasValue,
                legendAccessibilityLabel: legendAccessibilityLabel,
                accessibilityValue: accessibilityValue,
                tooltip: tooltip
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MonthlyHeatmapHeader: View {
    let month: Date
    let totalText: String
    let canMoveBackward: Bool
    let canMoveForward: Bool
    let moveBackward: () -> Void
    let moveForward: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MonthNavigationButton(
                systemImage: "chevron.left",
                accessibilityLabel: "前の月",
                isEnabled: canMoveBackward,
                action: moveBackward
            )

            VStack(alignment: .center, spacing: 2) {
                Text(DateDisplayFormatter.yearMonth(from: month))
                    .font(.headline)
                Text(totalText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: MonthlyHeatmapStyle.valueColumnWidth, alignment: .center)

            MonthNavigationButton(
                systemImage: "chevron.right",
                accessibilityLabel: "次の月",
                isEnabled: canMoveForward,
                action: moveForward
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct MonthNavigationButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringResource
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(
                    width: MonthlyHeatmapStyle.navigationButtonLength,
                    height: MonthlyHeatmapStyle.navigationButtonLength
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0)
        .frame(
            width: MonthlyHeatmapStyle.navigationButtonLength,
            height: MonthlyHeatmapStyle.navigationButtonLength
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHidden(!isEnabled)
    }
}

private struct MonthlyHeatmapContent<Item, Tooltip>: View
where Item: Identifiable, Item.ID == Date, Tooltip: View {
    let days: [Item]
    let date: KeyPath<Item, Date>
    let intensityLevel: KeyPath<Item, Int>
    let isInDisplayedMonth: KeyPath<Item, Bool>
    let hasValue: KeyPath<Item, Bool>
    let legendAccessibilityLabel: LocalizedStringResource
    let accessibilityValue: (Item) -> String
    @ViewBuilder let tooltip: (Item) -> Tooltip

    var body: some View {
        VStack(spacing: 12) {
            MonthlyHeatmapCalendar(
                days: days,
                date: date,
                intensityLevel: intensityLevel,
                isInDisplayedMonth: isInDisplayedMonth,
                hasValue: hasValue,
                accessibilityValue: accessibilityValue,
                tooltip: tooltip
            )
            MonthlyHeatmapLegend(accessibilityLabel: legendAccessibilityLabel)
        }
        .frame(width: MonthlyHeatmapStyle.calendarWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct MonthlyHeatmapCalendar<Item, Tooltip>: View
where Item: Identifiable, Item.ID == Date, Tooltip: View {
    private static var columns: [GridItem] {
        Array(
            repeating: GridItem(
                .fixed(MonthlyHeatmapStyle.cellLength),
                spacing: MonthlyHeatmapStyle.cellSpacing
            ),
            count: MonthlyHeatmapStyle.weekdayCount
        )
    }
    private static var weekdaySymbols: [String] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar.veryShortStandaloneWeekdaySymbols
    }

    let days: [Item]
    let date: KeyPath<Item, Date>
    let intensityLevel: KeyPath<Item, Int>
    let isInDisplayedMonth: KeyPath<Item, Bool>
    let hasValue: KeyPath<Item, Bool>
    let accessibilityValue: (Item) -> String
    @ViewBuilder let tooltip: (Item) -> Tooltip

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: Self.columns, spacing: MonthlyHeatmapStyle.cellSpacing) {
                ForEach(Self.weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: MonthlyHeatmapStyle.cellLength)
                }
            }

            LazyVGrid(columns: Self.columns, spacing: MonthlyHeatmapStyle.cellSpacing) {
                ForEach(days) { day in
                    MonthlyHeatmapDayCell(
                        day: day,
                        date: date,
                        intensityLevel: intensityLevel,
                        isInDisplayedMonth: isInDisplayedMonth,
                        hasValue: hasValue,
                        accessibilityValue: accessibilityValue,
                        tooltip: tooltip
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: MonthlyHeatmapStyle.calendarHeight, alignment: .center)
    }
}

private struct MonthlyHeatmapDayCell<Item, Tooltip>: View where Tooltip: View {
    let day: Item
    let date: KeyPath<Item, Date>
    let intensityLevel: KeyPath<Item, Int>
    let isInDisplayedMonth: KeyPath<Item, Bool>
    let hasValue: KeyPath<Item, Bool>
    let accessibilityValue: (Item) -> String
    @ViewBuilder let tooltip: (Item) -> Tooltip
    @State private var isHovered = false
    @State private var tooltipHeight: CGFloat = 0

    var body: some View {
        let isVisible = day[keyPath: isInDisplayedMonth]

        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(MonthlyHeatmapStyle.color(for: day[keyPath: intensityLevel]))

            if isVisible {
                Text(day[keyPath: date], format: .dateTime.day())
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(day[keyPath: hasValue] ? .white : .secondary)
            }
        }
        .frame(width: MonthlyHeatmapStyle.cellLength, height: MonthlyHeatmapStyle.cellLength)
        .opacity(isVisible ? 1 : 0)
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
                tooltip(day)
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        tooltipHeight = height
                    }
                    .offset(y: -(tooltipHeight + MonthlyHeatmapStyle.cellSpacing))
            }
        }
        .zIndex(isHovered ? 1 : 0)
        .allowsHitTesting(isVisible)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day[keyPath: date].formatted(.dateTime.year().month().day().weekday()))
        .accessibilityValue(accessibilityValue(day))
        .accessibilityHidden(!isVisible)
    }
}

private struct MonthlyHeatmapLegend: View {
    let accessibilityLabel: LocalizedStringResource

    var body: some View {
        HStack(spacing: 5) {
            Spacer()
            Text("少ない")
            ForEach(0..<MonthlyHeatmapStyle.legendLevelCount, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(MonthlyHeatmapStyle.color(for: level))
                    .frame(width: 12, height: 12)
            }
            Text("多い")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}
