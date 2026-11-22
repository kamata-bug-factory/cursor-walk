import Foundation

/// 推定スクロール回転数を表示用に整形する。
enum ScrollRotationFormatter {
    // Windows uses 3 lines as the default scrolling amount for one wheel step.
    // https://learn.microsoft.com/en-gb/windows/win32/inputdev/about-mouse-input
    private static let linesPerStep = 3.0

    // The BenQ ZOWIE C series wheel has 24 steps per rotation.
    // https://zowie.benq.com/en-us/news/2021/EC3-C.html
    private static let stepsPerRotation = 24.0

    static func rotations(from lineUnits: Double) -> Double {
        lineUnits / (linesPerStep * stepsPerRotation)
    }

    static func formatted(lineUnits: Double) -> String {
        let rotations = rotations(from: lineUnits)
        return "\(rotations.formatted(.number.precision(.fractionLength(2))))回転"
    }
}
