//
//  TooltipStyle.swift
//  cursor-walk
//

import SwiftUI

/// グラフとヒートマップのツールチップで共通する外観と操作特性。
private struct TooltipModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            .allowsHitTesting(false)
    }
}

extension View {
    func tooltipStyle() -> some View {
        modifier(TooltipModifier())
    }
}
