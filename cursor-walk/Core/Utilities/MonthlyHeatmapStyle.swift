//
//  MonthlyHeatmapStyle.swift
//  cursor-walk
//

import SwiftUI

/// 距離とクリックの月間ヒートマップで共有する表示ルール。
enum MonthlyHeatmapStyle {
    static let retainedMonthOffset = -12
    static let valueColumnWidth: CGFloat = 120
    static let navigationButtonLength: CGFloat = 28
    static let cellLength: CGFloat = 26
    static let cellSpacing: CGFloat = 5
    static let weekdayCount = 7
    static let calendarWidth = cellLength * CGFloat(weekdayCount) + cellSpacing * CGFloat(weekdayCount - 1)
    static let calendarHeight: CGFloat = 201
    static let legendLevelCount = 5

    private static let emptyOpacity = 0.12
    private static let minimumIntensityOpacity = 0.06
    private static let intensityOpacityStep = 0.235

    static func color(for intensityLevel: Int) -> Color {
        guard intensityLevel > 0 else {
            return Color.secondary.opacity(emptyOpacity)
        }

        return Color.accentColor.opacity(
            minimumIntensityOpacity + Double(intensityLevel) * intensityOpacityStep
        )
    }
}
