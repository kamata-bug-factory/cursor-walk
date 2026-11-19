//
//  TodaySummary.swift
//  cursor-walk
//

import SwiftUI

/// 本日の計測値を表示する共通レイアウト。
struct TodaySummary<Details: View>: View {
    let title: String
    let primaryValue: String
    @ViewBuilder let details: () -> Details

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(primaryValue)
                .font(.system(size: AppLayout.primaryMetricFontSize, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            details()
        }
        .frame(maxWidth: .infinity)
    }
}
