//
//  DistanceTooltipStyle.swift
//  cursor-walk
//

import SwiftUI

/// 移動距離ツールチップで共通する外観と操作特性。
private struct DistanceTooltipModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            .allowsHitTesting(false)
    }
}

extension View {
    func distanceTooltipStyle() -> some View {
        modifier(DistanceTooltipModifier())
    }
}
