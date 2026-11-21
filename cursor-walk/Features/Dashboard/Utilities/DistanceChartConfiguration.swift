import Foundation

/// 週間距離チャートで使用する表示単位。
enum DistanceChartUnit {
    case meters
    case kilometers

    init(maximumPoints: Double) {
        self = DistanceFormatter.meters(for: maximumPoints) >= DistanceFormatter.metersPerKilometer
            ? .kilometers
            : .meters
    }

    var scale: Double {
        switch self {
        case .meters:
            DistanceFormatter.metersPerPoint
        case .kilometers:
            DistanceFormatter.metersPerPoint / DistanceFormatter.metersPerKilometer
        }
    }

    var symbol: String {
        switch self {
        case .meters:
            "m"
        case .kilometers:
            "km"
        }
    }
}

/// データの最大値から、読みやすいY軸の上限と目盛りを求める。
struct DistanceAxisConfiguration {
    private static let targetIntervalCount = 5.0

    let upperBound: Double
    let values: [Double]

    init(maximumValue: Double) {
        guard maximumValue > 0 else {
            upperBound = 100
            values = [0, 20, 40, 60, 80, 100]
            return
        }

        let step = Self.niceStep(for: maximumValue / Self.targetIntervalCount)
        let intervalCount = max(1, Int(ceil(maximumValue / step)))

        upperBound = Double(intervalCount) * step
        values = (0...intervalCount).map { Double($0) * step }
    }

    /// 1、2、2.5、5、10の系列から、必要量以上の最小の間隔を選ぶ。
    private static func niceStep(for minimumStep: Double) -> Double {
        let magnitude = pow(10, floor(log10(minimumStep)))
        let normalizedStep = minimumStep / magnitude

        let multiplier: Double
        switch normalizedStep {
        case ...1:
            multiplier = 1
        case ...2:
            multiplier = 2
        case ...2.5:
            multiplier = 2.5
        case ...5:
            multiplier = 5
        default:
            multiplier = 10
        }

        return multiplier * magnitude
    }
}
