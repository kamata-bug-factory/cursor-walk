//
//  MouseClickTracker.swift
//  cursor-walk
//

import AppKit
import Combine
import Foundation

/// マウスクリックを計測し、日別に保存する。
final class MouseClickTracker: ObservableObject {
    private static let retentionDays = 400
    private static let saveDelay: TimeInterval = 1

    @Published private(set) var todayClicks = ClickBreakdown()
    @Published private(set) var dailyClicks: [DailyClickCount] = []

    private let calendar = Calendar.current
    private let fileManager = FileManager.default
    private let storageURL: URL?
    private let currentDayProvider: CurrentDayProvider?
    private var currentDayObserverID: CurrentDayProvider.ObserverID?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingSaveWorkItem: DispatchWorkItem?
    private var currentDay: Date?
    private var currentDayIndex: Int?

    init(currentDayProvider: CurrentDayProvider) {
        self.currentDayProvider = currentDayProvider
        storageURL = Self.makeStorageURL(using: fileManager)
        loadDailyClicks()
        currentDayObserverID = currentDayProvider.addObserver { [weak self] day in
            self?.updateCurrentDay(to: day)
        }
        startTracking()
    }

    /// 開発時のSwiftUIプレビュー用
    init(previewClicks: [DailyClickCount]) {
        currentDayProvider = nil
        storageURL = nil
        dailyClicks = previewClicks
        todayClicks = clicks(for: .now)
    }

    deinit {
        currentDayProvider?.removeObserver(currentDayObserverID)
        stopTracking()
        pendingSaveWorkItem?.cancel()
        saveDailyClicks()
    }

    /// アプリ内外のマウスボタン押下を監視する。
    func startTracking() {
        guard globalMonitor == nil, localMonitor == nil else {
            return
        }

        let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        // グローバルモニターは自アプリのイベントを受け取らないため、
        // ローカルモニターと組み合わせても二重計上にならない。
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleClick(buttonNumber: event.buttonNumber)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleClick(buttonNumber: event.buttonNumber)
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
        return saveDailyClicks()
    }

    func clicks(for date: Date) -> ClickBreakdown {
        let day = calendar.startOfDay(for: date)
        return dailyClicks.first(where: { calendar.isDate($0.day, inSameDayAs: day) })?.clicks
            ?? ClickBreakdown()
    }

    private func handleClick(buttonNumber: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.record(buttonNumber: buttonNumber, at: .now)
        }
    }

    private func record(buttonNumber: Int, at date: Date) {
        currentDayProvider?.refresh(at: date)
        let day = calendar.startOfDay(for: date)
        guard let index = indexForCurrentDay(day) else {
            return
        }

        dailyClicks[index].clicks.record(buttonNumber: buttonNumber)
        todayClicks = dailyClicks[index].clicks
        scheduleSave()
    }

    private func updateCurrentDay(to day: Date) {
        currentDay = day
        currentDayIndex = dailyClicks.firstIndex(where: { $0.day == day })
        todayClicks = currentDayIndex.map { dailyClicks[$0].clicks } ?? ClickBreakdown()
    }

    private func indexForCurrentDay(_ day: Date) -> Int? {
        if currentDay == day, let currentDayIndex {
            return currentDayIndex
        }

        pruneClicks(keepingFrom: day)

        if let index = dailyClicks.firstIndex(where: { $0.day == day }) {
            currentDay = day
            currentDayIndex = index
            return index
        }

        dailyClicks.append(DailyClickCount(day: day, clicks: ClickBreakdown()))
        dailyClicks.sort { $0.day < $1.day }

        guard let index = dailyClicks.firstIndex(where: { $0.day == day }) else {
            return nil
        }

        currentDay = day
        currentDayIndex = index
        return index
    }

    private func loadDailyClicks() {
        guard
            let storageURL,
            let data = try? Data(contentsOf: storageURL),
            let decodedClicks = try? JSONDecoder().decode([DailyClickCount].self, from: data)
        else {
            return
        }

        dailyClicks = decodedClicks
        let today = calendar.startOfDay(for: .now)
        pruneClicks(keepingFrom: today)

        if let index = dailyClicks.firstIndex(where: { $0.day == today }) {
            currentDay = today
            currentDayIndex = index
            todayClicks = dailyClicks[index].clicks
        }
    }

    private func pruneClicks(keepingFrom currentDay: Date) {
        guard let earliestDay = calendar.date(
            byAdding: .day,
            value: -(Self.retentionDays - 1),
            to: currentDay
        ) else {
            return
        }

        let retainedClicks = dailyClicks
            .filter { $0.day >= earliestDay && $0.day <= currentDay }
            .sorted { $0.day < $1.day }

        guard retainedClicks != dailyClicks else {
            return
        }

        dailyClicks = retainedClicks
        _ = saveDailyClicks()
    }

    @discardableResult
    private func saveDailyClicks() -> Bool {
        guard
            let storageURL,
            let data = try? JSONEncoder().encode(dailyClicks)
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

    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.saveDailyClicks()
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.saveDelay,
            execute: workItem
        )
    }

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
            return appDirectoryURL.appendingPathComponent("daily-clicks.json")
        } catch {
            return nil
        }
    }
}
