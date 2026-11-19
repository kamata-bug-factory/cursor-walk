//
//  ClickSummary.swift
//  cursor-walk
//

import SwiftUI

/// 本日のクリック合計とボタン別の内訳。
struct ClickSummary: View {
    private static let dateStyle = Date.FormatStyle()
        .month(.defaultDigits)
        .day()
        .weekday(.abbreviated)
        .locale(Locale(identifier: "ja_JP"))

    let date: Date
    let clicks: ClickBreakdown

    var body: some View {
        TodaySummary(
            title: "\(date.formatted(Self.dateStyle))のクリック回数",
            primaryValue: ClickFormatter.countWithUnit(clicks.total)
        ) {
            ClickBreakdownView(clicks: clicks)
        }
    }
}

private struct ClickBreakdownView: View {
    let clicks: ClickBreakdown

    var body: some View {
        HStack(spacing: 12) {
            ClickBreakdownItem(title: "左", count: clicks.left)
            ClickBreakdownItem(title: "右", count: clicks.right)
            ClickBreakdownItem(title: "中", count: clicks.middle)

            ClickBreakdownItem(title: "他", count: clicks.other)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}

private struct ClickBreakdownItem: View {
    let title: LocalizedStringResource
    let count: Int

    var body: some View {
        Text("\(title) \(ClickFormatter.count(count))")
    }
}
