import AppKit
import SwiftUI

/// メニューバーでの操作とアプリのライフサイクルを管理する。
@MainActor
final class StatusBarController: NSObject, NSApplicationDelegate {
    private let mouseTracker = MouseTracker()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    /// 起動完了時に計測画面とメニューバーアイコンを準備する。
    ///
    /// - Parameter notification: アプリの起動完了通知。
    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView(mouseTracker: mouseTracker)
        )

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "cursorarrow.motionlines",
                accessibilityDescription: "CursorWalk"
            )
            button.toolTip = "CursorWalk"
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    /// クリックの種類に応じて計測画面を開閉するか、終了メニューを表示する。
    ///
    /// 右クリックまたはControlキーを押しながらのクリックではコンテキストメニューを表示する。
    /// 通常の左クリックでは計測画面を開閉し、画面を閉じた後も計測を継続する。
    ///
    /// - Parameter sender: クリックされたメニューバーのボタン。
    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isContextClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true

        if isContextClick {
            popover.performClose(nil)
            let menu = NSMenu()
            let quitItem = NSMenuItem(
                title: "CursorWalkを終了",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
            quitItem.target = NSApp
            menu.addItem(quitItem)

            // メニューバーアイコンの直下にコンテキストメニューを表示する。
            let menuOrigin = NSPoint(
                x: sender.bounds.minX,
                y: sender.isFlipped ? sender.bounds.maxY : sender.bounds.minY
            )
            sender.highlight(true)
            defer { sender.highlight(false) }
            menu.popUp(positioning: nil, at: menuOrigin, in: sender)
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    /// 記録を保存し、アプリを終了できるか判定する。
    ///
    /// 保存に失敗した場合は、終了のキャンセルまたは保存せずに終了する選択肢を表示する。
    ///
    /// - Parameter sender: 終了を要求しているアプリ。
    /// - Returns: 保存成功時または強制終了を選んだ場合は `.terminateNow`、
    ///   キャンセルを選んだ場合は `.terminateCancel`。
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if mouseTracker.saveBeforeQuitting() {
            return .terminateNow
        }

        popover.performClose(nil)
        sender.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "記録を保存できませんでした"
        alert.informativeText = "空き容量や保存先のアクセス権を確認して、もう一度お試しください。強制終了すると、未保存の記録は失われます。"
        alert.addButton(withTitle: "キャンセル")
        alert.addButton(withTitle: "強制終了")
        return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
    }

    /// 終了確定後にマウスイベントの監視を解除し、メニューバーアイコンを取り除く。
    ///
    /// - Parameter notification: アプリの終了直前の通知。
    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker.stopTracking()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
