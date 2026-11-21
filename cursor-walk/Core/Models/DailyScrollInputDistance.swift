import Foundation

/// 1日分のスクロール入力距離（ポイント）。
struct DailyScrollInputDistance: Codable, Equatable, Identifiable {
    let day: Date
    var points: Double

    var id: Date { day }

    init(day: Date, points: Double) {
        self.day = day
        self.points = points
    }
}
