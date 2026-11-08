//
//  DistanceFormatter.swift
//  cursor-walk
//

import Foundation

/// 移動距離の単位換算と表示形式をまとめたユーティリティ。
enum DistanceFormatter {
    /// 1ポイントあたりの距離（メートル）。
    static let metersPerPoint = 0.0254 / 72.0

    /// ポイント単位の距離をメートルへ換算する。
    ///
    /// - Parameter points: 変換対象の距離（ポイント）。
    /// - Returns: メートル単位の距離。
    static func meters(for points: Double) -> Double {
        points * metersPerPoint
    }

    /// ポイント単位の距離を、センチメートル、メートル、またはキロメートル表記へ変換する。
    ///
    /// - Parameter points: 変換対象の距離（ポイント）。
    /// - Returns: 距離と単位を含む表示用文字列。
    static func formattedDistance(for points: Double) -> String {
        let meters = meters(for: points)

        if meters >= 1_000 {
            return "\((meters / 1_000).formatted(.number.precision(.fractionLength(2)))) km"
        }

        if meters >= 1 {
            return "\(meters.formatted(.number.precision(.fractionLength(2)))) m"
        }

        return "\((meters * 100).formatted(.number.precision(.fractionLength(0)))) cm"
    }

    /// ポイント単位の距離を、小数第2位までのメートル表記へ変換する。
    ///
    /// - Parameter points: 変換対象の距離（ポイント）。
    /// - Returns: 距離とメートル単位を含む表示用文字列。
    static func formattedMeters(for points: Double) -> String {
        "\(meters(for: points).formatted(.number.precision(.fractionLength(2)))) m"
    }
}
