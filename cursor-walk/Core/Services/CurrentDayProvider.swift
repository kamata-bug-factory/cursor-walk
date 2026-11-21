import Foundation

/// 入力イベントを契機に日付変更を検知し、各計測サービスへ通知する。
final class CurrentDayProvider {
    typealias ObserverID = UUID

    private let calendar: Calendar
    private var currentDay: Date
    private var observers: [ObserverID: (Date) -> Void] = [:]

    init(calendar: Calendar = .current, referenceDate: Date = .now) {
        self.calendar = calendar
        currentDay = calendar.startOfDay(for: referenceDate)
    }

    func addObserver(_ observer: @escaping (Date) -> Void) -> ObserverID {
        let id = ObserverID()
        observers[id] = observer
        observer(currentDay)
        return id
    }

    func removeObserver(_ id: ObserverID?) {
        guard let id else { return }
        observers[id] = nil
    }

    func refresh(at date: Date) {
        let day = calendar.startOfDay(for: date)
        guard day != currentDay else { return }

        currentDay = day
        for observer in observers.values {
            observer(day)
        }
    }
}
