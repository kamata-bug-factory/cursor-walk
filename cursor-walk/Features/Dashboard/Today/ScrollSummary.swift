import SwiftUI

struct ScrollSummary: View {
    private static let dateStyle = Date.FormatStyle()
        .month(.defaultDigits)
        .day()
        .weekday(.abbreviated)
        .locale(Locale(identifier: "ja_JP"))

    let date: Date
    let points: Double

    var body: some View {
        TodaySummary(
            title: "\(date.formatted(Self.dateStyle))のスクロール操作量",
            primaryValue: DistanceFormatter.formattedDistance(for: points)
        ) {
            Text("\(Int(points)) pts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
