import Foundation

/// 1日分のスクロール入力を行相当量で保持する。
struct DailyScrollInput: Codable, Equatable, Identifiable {
    let day: Date
    var lineUnits: Double

    var id: Date { day }

    init(day: Date, lineUnits: Double) {
        self.day = day
        self.lineUnits = lineUnits
    }
}
