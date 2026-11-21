import AppKit
import Combine
import Foundation

/// スクロール入力を論理ポイントへ換算して計測し、日別に保存する。
final class MouseScrollTracker: ObservableObject {
    private static let retentionDays = 400
    private static let saveDelay: TimeInterval = 1
    private static let fallbackBackingScaleFactor: CGFloat = 2

    @Published private(set) var todayPoints = 0.0
    @Published private(set) var dailyDistances: [DailyScrollDistance] = []

    private let calendar = Calendar.current
    private let fileManager = FileManager.default
    private let storageURL: URL?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingSaveWorkItem: DispatchWorkItem?
    private var currentDay: Date?
    private var currentDayIndex: Int?

    init() {
        storageURL = Self.makeStorageURL(using: fileManager)
        loadDailyDistances()
        startTracking()
    }

    init(previewDistances: [DailyScrollDistance]) {
        storageURL = nil
        dailyDistances = previewDistances
        todayPoints = points(for: .now)
    }

    deinit {
        stopTracking()
        pendingSaveWorkItem?.cancel()
        saveDailyDistances()
    }

    /// アプリ内外の縦・横方向のスクロール操作を監視する。
    func startTracking() {
        guard globalMonitor == nil, localMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScroll(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScroll(event)
            return event
        }
    }

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

    func saveBeforeQuitting() -> Bool {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        return saveDailyDistances()
    }

    func points(for date: Date) -> Double {
        let day = calendar.startOfDay(for: date)
        return dailyDistances.first(where: { calendar.isDate($0.day, inSameDayAs: day) })?.points ?? 0
    }

    private func handleScroll(_ event: NSEvent) {
        guard let points = scrollPoints(for: event) else { return }
        guard points > 0 else { return }

        DispatchQueue.main.async { [weak self] in
            self?.record(points: points, at: .now)
        }
    }

    /// 精密差分は各軸の絶対値を加算し、通常ホイールのピクセル差分は論理ポイントへ変換する。
    private func scrollPoints(for event: NSEvent) -> Double? {
        if event.hasPreciseScrollingDeltas {
            return abs(Double(event.scrollingDeltaX)) + abs(Double(event.scrollingDeltaY))
        }

        guard let cgEvent = event.cgEvent else { return nil }
        let horizontalPixelDelta = Double(
            cgEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
        )
        let verticalPixelDelta = Double(
            cgEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        )

        let scale = screenUnderPointer?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor
            ?? Self.fallbackBackingScaleFactor
        return (abs(horizontalPixelDelta) + abs(verticalPixelDelta)) / scale
    }

    private var screenUnderPointer: NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        }
    }

    private func record(points: Double, at date: Date) {
        let day = calendar.startOfDay(for: date)
        guard let index = indexForCurrentDay(day) else { return }

        dailyDistances[index].points += points
        todayPoints = dailyDistances[index].points
        scheduleSave()
    }

    private func indexForCurrentDay(_ day: Date) -> Int? {
        if currentDay == day, let currentDayIndex { return currentDayIndex }
        pruneDistances(keepingFrom: day)

        if let index = dailyDistances.firstIndex(where: { $0.day == day }) {
            currentDay = day
            currentDayIndex = index
            return index
        }

        dailyDistances.append(DailyScrollDistance(day: day, points: 0))
        dailyDistances.sort { $0.day < $1.day }
        guard let index = dailyDistances.firstIndex(where: { $0.day == day }) else { return nil }
        currentDay = day
        currentDayIndex = index
        return index
    }

    private func loadDailyDistances() {
        guard let storageURL,
              let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([DailyScrollDistance].self, from: data)
        else { return }

        dailyDistances = decoded
        let today = calendar.startOfDay(for: .now)
        pruneDistances(keepingFrom: today)
        if let index = dailyDistances.firstIndex(where: { $0.day == today }) {
            currentDay = today
            currentDayIndex = index
            todayPoints = dailyDistances[index].points
        }
    }

    private func pruneDistances(keepingFrom currentDay: Date) {
        guard let earliestDay = calendar.date(
            byAdding: .day,
            value: -(Self.retentionDays - 1),
            to: currentDay
        ) else { return }

        let retained = dailyDistances
            .filter { $0.day >= earliestDay && $0.day <= currentDay }
            .sorted { $0.day < $1.day }
        guard retained != dailyDistances else { return }
        dailyDistances = retained
        _ = saveDailyDistances()
    }

    @discardableResult
    private func saveDailyDistances() -> Bool {
        guard let storageURL,
              let data = try? JSONEncoder().encode(dailyDistances)
        else { return false }

        do {
            try data.write(to: storageURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.saveDailyDistances() }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.saveDelay, execute: workItem)
    }

    private static func makeStorageURL(using fileManager: FileManager) -> URL? {
        guard let supportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }

        let directoryURL = supportURL.appendingPathComponent("cursor-walk", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            return directoryURL.appendingPathComponent("daily-scroll-distances.json")
        } catch {
            return nil
        }
    }
}
