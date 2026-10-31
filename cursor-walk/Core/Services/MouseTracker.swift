//
//  MouseTracker.swift
//  cursor-walk
//
//  Created by Kazuki Kamata on 2026/10/31.
//

import Foundation
import Combine
import AppKit

class MouseTracker: ObservableObject {
    /// 累計の移動ピクセル数
    @Published var totalPixels: Double = 0.0
    
    private var lastLocation: NSPoint?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    init() {
        startTracking()
    }
    
    deinit {
        stopTracking()
    }
    
    /// マウス監視を開始する
    func startTracking() {
        // 1. 他のアプリ上のマウス移動も監視する（グローバル）
        // ※ 要アクセシビリティ権限
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handleMovement(to: NSEvent.mouseLocation)
        }
        
        // 2. 自アプリ内のマウス移動を監視する（ローカル）
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handleMovement(to: NSEvent.mouseLocation)
            return event
        }
    }
    
    /// マウス監視を停止する
    func stopTracking() {
        if let global = globalMonitor {
            NSEvent.removeMonitor(global)
        }
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
        }
    }
    
    /// 座標の差分から移動距離（ピクセル）を計算する
    private func handleMovement(to currentLocation: NSPoint) {
        if let last = lastLocation {
            let dx = currentLocation.x - last.x
            let dy = currentLocation.y - last.y
            let distance = sqrt(dx * dx + dy * dy) // 三平方の定理で直線距離を計算
            
            // 画面間の瞬間移動やスリープ復帰時の異常値（500px以上）は無視する
            if distance < 500 {
                DispatchQueue.main.async {
                    self.totalPixels += distance
                }
            }
        }
        lastLocation = currentLocation
    }
}
