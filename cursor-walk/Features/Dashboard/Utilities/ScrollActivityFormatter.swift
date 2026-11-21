import Foundation

/// スクロール操作量を単位なしの整数として表示する。
enum ScrollActivityFormatter {
    static func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }
}
