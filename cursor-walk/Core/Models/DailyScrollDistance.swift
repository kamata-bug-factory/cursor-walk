import Foundation

/// 1日分の精密スクロール距離（ポイント）。
struct DailyScrollDistance: Codable, Equatable, Identifiable {
    let day: Date
    var points: Double

    var id: Date { day }

    init(day: Date, points: Double) {
        self.day = day
        self.points = points
    }
}
