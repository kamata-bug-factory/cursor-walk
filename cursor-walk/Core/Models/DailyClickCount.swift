//
//  DailyClickCount.swift
//  cursor-walk
//

import Foundation

/// マウスボタンごとのクリック回数。
struct ClickBreakdown: Codable, Equatable {
    var left = 0
    var right = 0
    var middle = 0
    var other = 0

    var total: Int {
        left + right + middle + other
    }

    mutating func record(buttonNumber: Int) {
        switch buttonNumber {
        case 0:
            left += 1
        case 1:
            right += 1
        case 2:
            middle += 1
        default:
            other += 1
        }
    }

    nonisolated static func + (lhs: ClickBreakdown, rhs: ClickBreakdown) -> ClickBreakdown {
        ClickBreakdown(
            left: lhs.left + rhs.left,
            right: lhs.right + rhs.right,
            middle: lhs.middle + rhs.middle,
            other: lhs.other + rhs.other
        )
    }
}

/// 1日分のクリック記録。
struct DailyClickCount: Codable, Equatable, Identifiable {
    let day: Date
    var clicks: ClickBreakdown

    var id: Date { day }
}
