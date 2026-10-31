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
            
            // 累計ピクセル数を整数表示
            Text("\(Int(mouseTracker.totalPixels))")
                .font(.system(size: 56, weight: .bold, design: .rounded))
            
            Text("pixels")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 280, height: 180)
        .padding()
    }
}

#Preview {
    ContentView()
}
