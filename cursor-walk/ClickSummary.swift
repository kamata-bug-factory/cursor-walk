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
        VStack(spacing: 8) {
            Text("\(date.formatted(Self.dateStyle))のクリック回数")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(ClickFormatter.countWithUnit(clicks.total))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            ClickBreakdownView(clicks: clicks)
        }
        .frame(maxWidth: .infinity)
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
