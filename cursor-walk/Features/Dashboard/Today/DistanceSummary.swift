//
//  DistanceSummary.swift
//  cursor-walk
//

import SwiftUI

/// 本日の移動距離を表示するビュー。
struct DistanceSummary: View {
    private static let dateStyle = Date.FormatStyle()
        .month(.defaultDigits)
        .day()
        .weekday(.abbreviated)
        .locale(Locale(identifier: "ja_JP"))

    let date: Date
    let points: Double

    var body: some View {
        let formattedDate = date.formatted(Self.dateStyle)

        TodaySummary(
            title: "\(formattedDate)の移動距離",
            primaryValue: DistanceFormatter.formattedDistance(for: points)
        ) {
            DistanceDetailsView(points: points)
        }
    }
}

private struct DistanceDetailsView: View {
    let points: Double

    var body: some View {
        HStack(spacing: 8) {
            if DistanceFormatter.meters(for: points) >= DistanceFormatter.metersPerKilometer {
                Text(DistanceFormatter.formattedMeters(for: points))
            }

            Text("\(Int(points)) pts")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
