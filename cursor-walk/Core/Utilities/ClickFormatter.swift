//
//  ClickFormatter.swift
//  cursor-walk
//

import Foundation

enum ClickFormatter {
    static func count(_ value: Int) -> String {
        value.formatted(.number)
    }

    static func countWithUnit(_ value: Int) -> String {
        "\(count(value))回"
    }

    static func breakdown(_ clicks: ClickBreakdown) -> String {
        "(左\(count(clicks.left))/右\(count(clicks.right))/中\(count(clicks.middle))/他\(count(clicks.other)))"
    }
}
