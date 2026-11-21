import Foundation

enum ScrollFormatter {
    static func formattedDistance(for points: Double) -> String {
        DistanceFormatter.formattedDistance(for: points)
    }
}
