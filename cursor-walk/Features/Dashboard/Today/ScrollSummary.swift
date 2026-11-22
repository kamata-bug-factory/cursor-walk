import SwiftUI

struct ScrollSummary: View {
    private static let dateStyle = Date.FormatStyle()
        .month(.defaultDigits)
        .day()
        .weekday(.abbreviated)
        .locale(Locale(identifier: "ja_JP"))

    let date: Date
    let lineUnits: Double

    var body: some View {
        TodaySummary(
            title: "\(date.formatted(Self.dateStyle))の推定スクロール回転数",
            primaryValue: ScrollRotationFormatter.formatted(lineUnits: lineUnits)
        ) {
            EmptyView()
        }
    }
}
