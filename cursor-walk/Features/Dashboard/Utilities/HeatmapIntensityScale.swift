import Foundation

/// 値の順位からヒートマップの濃淡レベルを求める。
struct HeatmapIntensityScale<Value: Comparable> {
    private static var minimumLevel: Int { 1 }
    private static var maximumLevel: Int { 4 }

    private let sortedPositiveValues: [Value]

    init(positiveValues: some Sequence<Value>) {
        sortedPositiveValues = positiveValues.sorted()
    }

    func level(for value: Value, hasValue: Bool) -> Int {
        guard hasValue else {
            return 0
        }
        guard !sortedPositiveValues.isEmpty else {
            return Self.maximumLevel
        }

        let upperRank = (sortedPositiveValues.lastIndex { $0 <= value } ?? -1) + 1
        let percentile = Double(upperRank) / Double(sortedPositiveValues.count)
        let calculatedLevel = Int(ceil(percentile * Double(Self.maximumLevel)))
        return max(Self.minimumLevel, min(Self.maximumLevel, calculatedLevel))
    }
}
