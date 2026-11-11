//
//  MouseTracker.swift
//  cursor-walk
//

import AppKit
import Combine
import Foundation

/// マウスの移動距離を計測・管理する。
final class MouseTracker: ObservableObject {
    private static let retentionDays = 30

    /// 今日の累計移動ポイント数
    @Published private(set) var totalPoints: Double = 0.0

    /// 今日を含む直近30日間の日別移動距離
    @Published private(set) var dailyDistances: [DailyDistance] = []
    
    private let calendar = Calendar.current
    private let fileManager = FileManager.default
    private let storageURL: URL?
    private var lastLocation: NSPoint?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingSaveWorkItem: DispatchWorkItem?

    /// 保存済みの日別距離を復元して、マウス移動の監視を開始する。
    init() {
        storageURL = Self.makeStorageURL(using: fileManager)
        loadDailyDistances()
        startTracking()
    }

    /// 監視やファイルへのアクセスを行わず、プレビュー用の記録を設定する。
    ///
    /// - Parameter previewDistances: 画面に表示する日別の移動距離。
    init(previewDistances: [DailyDistance]) {
        storageURL = nil
        dailyDistances = previewDistances
        totalPoints = points(for: .now)
    }

    /// イベント監視を解除し、未保存の距離をディスクへ書き込む。
    deinit {
        stopTracking()
        pendingSaveWorkItem?.cancel()
        saveDailyDistances()
    }

    /// アプリ内外のマウス移動を監視する。
    func startTracking() {
        // 他のアプリ上でのマウス移動も監視する（アクセシビリティ権限が必要）。
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            self?.handleMovement(to: NSEvent.mouseLocation)
        }

        // 自アプリ内のマウス移動も監視する。
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] event in
            self?.handleMovement(to: NSEvent.mouseLocation)
            return event
        }
    }

    /// 登録済みのマウスイベント監視をすべて解除する。
    func stopTracking() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    /// 終了前に保存予約を取り消し、最新の記録を同期的に保存する。
    func saveBeforeQuitting() -> Bool {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        return saveDailyDistances()
    }

    /// 指定日の移動距離をポイント単位で返す。
    ///
    /// - Parameter date: 取得対象の日付。時刻部分は無視する。
    /// - Returns: 指定日の累計移動ポイント数。記録がない場合は `0`。
    func points(for date: Date) -> Double {
        let day = calendar.startOfDay(for: date)
        return dailyDistances.first(where: { calendar.isDate($0.day, inSameDayAs: day) })?.points ?? 0
    }

    /// 直前の座標との差分から移動距離を計算し、当日の記録へ加算する。
    ///
    /// - Parameter currentLocation: 最新のグローバルスクリーン座標。
    private func handleMovement(to currentLocation: NSPoint) {
        guard let lastLocation else {
            self.lastLocation = currentLocation
            return
        }

        let dx = currentLocation.x - lastLocation.x
        let dy = currentLocation.y - lastLocation.y
        let distance = sqrt(dx * dx + dy * dy)
        self.lastLocation = currentLocation

        // 画面間の瞬間移動やスリープ復帰時の異常値は無視する。
        guard distance < 500 else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.record(distance: distance, at: .now)
        }
    }

    /// 指定時刻の日別バケットへ距離を加算し、保存を予約する。
    ///
    /// - Parameters:
    ///   - distance: 加算する移動距離（ポイント）。
    ///   - date: 距離を記録する日時。
    private func record(distance: Double, at date: Date) {
        let day = calendar.startOfDay(for: date)
        pruneDistances(keepingFrom: day)

        if let index = dailyDistances.firstIndex(where: {
            calendar.isDate($0.day, inSameDayAs: day)
        }) {
            dailyDistances[index].points += distance
        } else {
            dailyDistances.append(DailyDistance(day: day, points: distance))
        }

        dailyDistances.sort { $0.day < $1.day }
        totalPoints = points(for: day)
        scheduleSave()
    }

    /// Application Support内のJSONファイルから日別距離を復元する。
    private func loadDailyDistances() {
        guard
            let storageURL,
            let data = try? Data(contentsOf: storageURL),
            let decodedDistances = try? JSONDecoder().decode([DailyDistance].self, from: data)
        else {
            return
        }

        dailyDistances = decodedDistances
        let today = calendar.startOfDay(for: .now)
        pruneDistances(keepingFrom: today)
        totalPoints = points(for: today)
    }

    /// 指定日を含む直近30日分以外の履歴を削除する。
    ///
    /// - Parameter currentDay: 保持期間の最終日。時刻部分は無視する。
    private func pruneDistances(keepingFrom currentDay: Date) {
        guard let earliestDay = calendar.date(byAdding: .day, value: -(Self.retentionDays - 1), to: currentDay) else {
            return
        }

        let retainedDistances = dailyDistances
            .filter { $0.day >= earliestDay && $0.day <= currentDay }
            .sorted { $0.day < $1.day }

        guard retainedDistances != dailyDistances else {
            return
        }

        dailyDistances = retainedDistances
        _ = saveDailyDistances()
    }

    /// 現在の日別距離をJSONへ原子的に保存する。
    ///
    /// - Returns: 保存に成功した場合は `true`。
    @discardableResult
    private func saveDailyDistances() -> Bool {
        guard
            let storageURL,
            let data = try? JSONEncoder().encode(dailyDistances)
        else {
            return false
        }

        do {
            try data.write(to: storageURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// 高頻度のマウスイベントによる保存処理を1秒後にまとめて予約する。
    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.saveDailyDistances()
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    /// 日別距離JSONの保存先を作成して返す。
    ///
    /// - Parameter fileManager: 保存先ディレクトリの取得と作成に使用するファイルマネージャ。
    /// - Returns: 作成済みの保存先URL。作成できない場合は `nil`。
    private static func makeStorageURL(using fileManager: FileManager) -> URL? {
        guard let applicationSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            return nil
        }

        let appDirectoryURL = applicationSupportURL
            .appendingPathComponent("cursor-walk", isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: appDirectoryURL,
                withIntermediateDirectories: true
            )
            return appDirectoryURL.appendingPathComponent("daily-distances.json")
        } catch {
            return nil
        }
    }
}

/// 1日分の移動距離の記録。
struct DailyDistance: Codable, Equatable, Identifiable {
    let day: Date
    var points: Double

    var id: Date { day }
}
