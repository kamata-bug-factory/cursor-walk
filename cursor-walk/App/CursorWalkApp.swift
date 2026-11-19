//
//  CursorWalkApp.swift
//  cursor-walk
//

import SwiftUI

/// CursorWalkアプリのエントリーポイント。
@main
struct CursorWalkApp: App {
    @NSApplicationDelegateAdaptor(StatusBarController.self) private var statusBarController

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
