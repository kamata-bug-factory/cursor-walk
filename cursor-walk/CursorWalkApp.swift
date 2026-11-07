//
//  CursorWalkApp.swift
//  cursor-walk
//

import SwiftUI

@main
struct CursorWalkApp: App {
    @StateObject private var mouseTracker = MouseTracker()

    var body: some Scene {
        MenuBarExtra("CursorWalk", systemImage: "cursorarrow.motionlines") {
            ContentView(mouseTracker: mouseTracker)
        }
        .menuBarExtraStyle(.window)
    }
}
