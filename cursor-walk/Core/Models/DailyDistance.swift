import Foundation

/// 1日分の移動距離の記録。
struct DailyDistance: Codable, Equatable, Identifiable {
    let day: Date
    var points: Double

    var id: Date { day }
}
