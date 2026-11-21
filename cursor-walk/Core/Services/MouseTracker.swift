//
//  MouseTracker.swift
//  cursor-walk
//

import AppKit
import Combine
import Foundation

/// マウスの移動距離を計測・管理する。
@MainActor
final class MouseTracker: ObservableObject {
    private static let retentionDays = 400
    private static let maximumTrackableDistance: CGFloat = 500
    private static let saveDelay: TimeInterval = 1

    /// 今日の累計移動ポイント数
    @Published private(set) var totalPoints: Double = 0.0

    /// 今日を含む直近400日間の日別移動距離
    @Published private(set) var dailyDistances: [DailyDistance] = []
    var hasStorageError: Bool { storageState.hasError }
    
    private let calendar = Calendar.current
    private let fileManager = FileManager.default
    private let storage: JSONFileStorage<[DailyDistance]>?
    private let currentDayProvider: CurrentDayProvider?
    private var currentDayObserverID: CurrentDayProvider.ObserverID?
    private var lastLocation: NSPoint?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingSaveWorkItem: DispatchWorkItem?
    private var currentDay: Date?
    private var currentDayIndex: Int?
    @Published private var storageState = StorageState.available

    /// 保存済みの日別距離を復元して、マウス移動の監視を開始する。
    init(currentDayProvider: CurrentDayProvider) {
        self.currentDayProvider = currentDayProvider
        storage = Self.makeStorageURL(using: fileManager).map(JSONFileStorage.init(url:))
        loadDailyDistances()
        currentDayObserverID = currentDayProvider.addObserver { [weak self] day in
            self?.updateCurrentDay(to: day)
        }
        startTracking()
    }

    /// 開発時のSwiftUIプレビュー用
    ///
    /// - Parameter previewDistances: 画面に表示する日別の移動距離。
    init(previewDistances: [DailyDistance], hasStorageError: Bool = false) {
        currentDayProvider = nil
        storage = nil
        dailyDistances = previewDistances
        totalPoints = points(for: .now)
        storageState = hasStorageError ? .writeFailed : .available
    }

    /// イベント監視を解除し、未保存の距離をディスクへ書き込む。
    isolated deinit {
        currentDayProvider?.removeObserver(currentDayObserverID)
        stopTracking()
        pendingSaveWorkItem?.cancel()
        saveDailyDistances()
    }

    /// アプリ内外のマウス移動を監視する。
    func startTracking() {
        guard globalMonitor == nil, localMonitor == nil else {
            return
        }

        // 他のアプリ上でのマウス移動も監視する。
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] _ in
            self?.handleMovement(to: NSEvent.mouseLocation)
        }

        // 自アプリ内のマウス移動も監視する。
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
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
        guard distance < Self.maximumTrackableDistance else {
            return
        }

        record(distance: distance, at: .now)
    }

    /// 指定時刻の日別バケットへ距離を加算し、保存を予約する。
    ///
    /// - Parameters:
    ///   - distance: 加算する移動距離（ポイント）。
    ///   - date: 距離を記録する日時。
    private func record(distance: Double, at date: Date) {
        currentDayProvider?.refresh(at: date)
        let day = calendar.startOfDay(for: date)
        guard let index = indexForCurrentDay(day) else {
            return
        }

        dailyDistances[index].points += distance
        totalPoints = dailyDistances[index].points
        scheduleSave()
    }

    private func updateCurrentDay(to day: Date) {
        currentDay = day
        currentDayIndex = dailyDistances.firstIndex(where: { $0.day == day })
        totalPoints = currentDayIndex.map { dailyDistances[$0].points } ?? 0
    }

    /// 当日の記録位置を返す。履歴の整理と検索は日付が変わったときだけ行う。
    private func indexForCurrentDay(_ day: Date) -> Int? {
        if currentDay == day, let currentDayIndex {
            return currentDayIndex
        }

        pruneDistances(keepingFrom: day)

        if let index = dailyDistances.firstIndex(where: { $0.day == day }) {
            currentDay = day
            currentDayIndex = index
            return index
        }

        dailyDistances.append(DailyDistance(day: day, points: 0))
        dailyDistances.sort { $0.day < $1.day }

        guard let index = dailyDistances.firstIndex(where: { $0.day == day }) else {
            return nil
        }

        currentDay = day
        currentDayIndex = index
        return index
    }

    /// Application Support内のJSONファイルから日別距離を復元する。
    private func loadDailyDistances() {
        guard let storage else {
            return
        }

        guard let decodedDistances = try? storage.load() else {
            storageState = fileManager.fileExists(atPath: storage.url.path)
                ? .readFailed
                : .available
            return
        }

        dailyDistances = decodedDistances
        let today = calendar.startOfDay(for: .now)
        pruneDistances(keepingFrom: today)
        if let index = dailyDistances.firstIndex(where: { $0.day == today }) {
            currentDay = today
            currentDayIndex = index
            totalPoints = dailyDistances[index].points
        }
    }

    /// 指定日を含む直近400日分以外の履歴を削除する。
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
        guard storageState.allowsWriting else {
            return false
        }

        guard let storage else {
            storageState = .writeFailed
            return false
        }

        do {
            try storage.save(dailyDistances)
            storageState = .available
            return true
        } catch {
            storageState = .writeFailed
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.saveDelay, execute: workItem)
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
