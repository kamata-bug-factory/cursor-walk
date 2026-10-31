//
//  ContentView.swift
//  cursor-walk
//
//  Created by Kazuki Kamata on 2026/10/17.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var mouseTracker = MouseTracker()

    var body: some View {
        VStack(spacing: 16) {
            Text("CursorWalk")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 距離（m または km）を大きく表示
            Text(formattedDistance(points: mouseTracker.totalPoints))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            // 補助情報として生ポイント数も表示
            Text("(\(Int(mouseTracker.totalPoints)) pts)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 300, height: 180)
        .padding()
    }
    
    /// カーソルの移動ポイントを現実の距離（m / km）に変換する関数
    private func formattedDistance(points: Double) -> String {
        // 1インチ = 72ポイント = 0.0254メートル
        let metersPerPoint = 0.0254 / 72.0
        let totalMeters = points * metersPerPoint
        
        if totalMeters >= 1000 {
            let kilometers = totalMeters / 1000.0
            return String(format: "%.2f km", kilometers)
        } else {
            return String(format: "%.0f m", totalMeters)
        }
    }
}

#Preview {
    ContentView()
}
