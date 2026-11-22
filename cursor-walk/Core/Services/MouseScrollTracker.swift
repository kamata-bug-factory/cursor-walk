import AppKit
import Combine
import Foundation

/// スクロール操作量を行相当量へ正規化し、日別に保存する。
@MainActor
final class MouseScrollTracker: ObservableObject {
    private static let retentionDays = 400
    private static let saveDelay: TimeInterval = 1
    // Apple documents the default scale as approximately 10 pixels per line.
    // https://developer.apple.com/documentation/coregraphics/cgeventsource/pixelsperline
    private static let fallbackPixelsPerLine = 10.0

    @Published private(set) var todayLineUnits = 0.0
    @Published private(set) var dailyInputs: [DailyScrollInput] = []
    var hasStorageError: Bool { storageState.hasError }

    private let calendar = Calendar.autoupdatingCurrent
    private let fileManager = FileManager.default
    private let storage: JSONFileStorage<[DailyScrollInput]>?
    private let currentDayProvider: CurrentDayProvider?
    private var currentDayObserverID: CurrentDayProvider.ObserverID?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingSaveWorkItem: DispatchWorkItem?
    private var currentDay: Date?
    private var currentDayIndex: Int?
    @Published private var storageState = StorageState.available

    init(currentDayProvider: CurrentDayProvider) {
        self.currentDayProvider = currentDayProvider
        storage = Self.makeStorageURL(using: fileManager).map(JSONFileStorage.init(url:))
        loadDailyInputs()
        currentDayObserverID = currentDayProvider.addObserver { [weak self] day in
            self?.updateCurrentDay(to: day)
        }
        startTracking()
    }

    /// 開発時のSwiftUIプレビュー用
    init(previewInputs: [DailyScrollInput], hasStorageError: Bool = false) {
        currentDayProvider = nil
        storage = nil
        dailyInputs = previewInputs
        todayLineUnits = lineUnits(for: .now)
        storageState = hasStorageError ? .writeFailed : .available
    }

    isolated deinit {
        currentDayProvider?.removeObserver(currentDayObserverID)
        stopTracking()
        pendingSaveWorkItem?.cancel()
        saveDailyInputs()
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
        return saveDailyInputs()
    }

    func lineUnits(for date: Date) -> Double {
        let day = calendar.startOfDay(for: date)
        return dailyInputs.first(where: { calendar.isDate($0.day, inSameDayAs: day) })?.lineUnits ?? 0
    }

    private func handleScroll(_ event: NSEvent) {
        guard let lineUnits = scrollLineUnits(for: event) else { return }
        guard lineUnits > 0 else { return }

        record(lineUnits: lineUnits, at: .now)
    }

    /// ピクセル差分をイベントソースの1行あたりのピクセル数で正規化する。
    private func scrollLineUnits(for event: NSEvent) -> Double? {
        guard let cgEvent = event.cgEvent else { return nil }

        let pixelDelta: Double
        if event.hasPreciseScrollingDeltas {
            pixelDelta = abs(Double(event.scrollingDeltaX)) + abs(Double(event.scrollingDeltaY))
        } else {
            let horizontalPixelDelta = Double(
                cgEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
            )
            let verticalPixelDelta = Double(
                cgEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
            )
            pixelDelta = abs(horizontalPixelDelta) + abs(verticalPixelDelta)
        }

        let sourcePixelsPerLine = CGEventSource(event: cgEvent)?.pixelsPerLine
        let pixelsPerLine = sourcePixelsPerLine.flatMap { $0 > 0 ? $0 : nil }
            ?? Self.fallbackPixelsPerLine
        return pixelDelta / pixelsPerLine
    }

    private func record(lineUnits: Double, at date: Date) {
        currentDayProvider?.refresh(at: date)
        let day = calendar.startOfDay(for: date)
        guard let index = indexForCurrentDay(day) else { return }

        dailyInputs[index].lineUnits += lineUnits
        todayLineUnits = dailyInputs[index].lineUnits
        scheduleSave()
    }

    private func updateCurrentDay(to day: Date) {
        currentDay = day
        currentDayIndex = dailyInputs.firstIndex {
            calendar.isDate($0.day, inSameDayAs: day)
        }
        todayLineUnits = currentDayIndex.map { dailyInputs[$0].lineUnits } ?? 0
    }

    private func indexForCurrentDay(_ day: Date) -> Int? {
        if let currentDay,
           calendar.isDate(currentDay, inSameDayAs: day),
           let currentDayIndex {
            return currentDayIndex
        }
        pruneInputs(keepingFrom: day)

        if let index = dailyInputs.firstIndex(where: {
            calendar.isDate($0.day, inSameDayAs: day)
        }) {
            currentDay = day
            currentDayIndex = index
            return index
        }

        dailyInputs.append(DailyScrollInput(day: day, lineUnits: 0))
        dailyInputs.sort { $0.day < $1.day }
        guard let index = dailyInputs.firstIndex(where: {
            calendar.isDate($0.day, inSameDayAs: day)
        }) else { return nil }
        currentDay = day
        currentDayIndex = index
        return index
    }

    private func loadDailyInputs() {
        guard let storage else { return }

        guard let decoded = try? storage.load() else {
            storageState = fileManager.fileExists(atPath: storage.url.path)
                ? .readFailed
                : .available
            return
        }

        dailyInputs = decoded
        let today = calendar.startOfDay(for: .now)
        pruneInputs(keepingFrom: today)
        if let index = dailyInputs.firstIndex(where: {
            calendar.isDate($0.day, inSameDayAs: today)
        }) {
            currentDay = today
            currentDayIndex = index
            todayLineUnits = dailyInputs[index].lineUnits
        }
    }

    private func pruneInputs(keepingFrom currentDay: Date) {
        guard let earliestDay = calendar.date(
            byAdding: .day,
            value: -(Self.retentionDays - 1),
            to: currentDay
        ) else { return }

        let retained = dailyInputs
            .filter {
                calendar.compare($0.day, to: earliestDay, toGranularity: .day) != .orderedAscending
                    && calendar.compare($0.day, to: currentDay, toGranularity: .day) != .orderedDescending
            }
            .sorted { $0.day < $1.day }
        guard retained != dailyInputs else { return }
        dailyInputs = retained
        _ = saveDailyInputs()
    }

    @discardableResult
    private func saveDailyInputs() -> Bool {
        guard storageState.allowsWriting else { return false }

        guard let storage else {
            storageState = .writeFailed
            return false
        }

        do {
            try storage.save(dailyInputs)
            storageState = .available
            return true
        } catch {
            storageState = .writeFailed
            return false
        }
    }

    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.saveDailyInputs() }
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
            return directoryURL.appendingPathComponent("daily-scroll-inputs.json")
        } catch {
            return nil
        }
    }
}
