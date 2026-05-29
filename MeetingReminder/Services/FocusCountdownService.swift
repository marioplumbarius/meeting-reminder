import AppKit
import Combine
import Foundation

extension Notification.Name {
    static let focusCountdownResetPosition = Notification.Name("focusCountdownResetPosition")
}

@MainActor
final class FocusCountdownService: ObservableObject {
    @Published private(set) var nextEvent: MeetingEvent?
    @Published private(set) var remaining: TimeInterval = 0

    private let calendarService: any CalendarServiceProtocol
    private var timer: Timer?

    init(calendarService: any CalendarServiceProtocol) {
        self.calendarService = calendarService
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = Date()
        nextEvent = calendarService.events
            .filter { $0.startDate > now }
            .min(by: { $0.startDate < $1.startDate })
        remaining = max(0, nextEvent?.startDate.timeIntervalSince(now) ?? 0)
    }
}

@MainActor
final class FocusCountdownCoordinator: ObservableObject {
    static let enabledKey = "focusCountdownEnabled"

    private let service: FocusCountdownService
    private let windowController = FocusCountdownWindowController()
    private var cancellables = Set<AnyCancellable>()
    private var lastEnabled: Bool?

    init(calendarService: any CalendarServiceProtocol) {
        self.service = FocusCountdownService(calendarService: calendarService)
    }

    func start() {
        applyEnabledState()

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyEnabledState() }
            .store(in: &cancellables)
    }

    private func applyEnabledState() {
        let enabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        guard enabled != lastEnabled else { return }
        lastEnabled = enabled
        if enabled {
            service.start()
            windowController.show(service: service)
        } else {
            service.stop()
            windowController.close()
        }
    }
}
