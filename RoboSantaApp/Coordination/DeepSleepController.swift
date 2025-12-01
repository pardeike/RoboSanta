import AppKit
import Combine
import Foundation

/// Handles timed/manual deep sleep to park servos while keeping the rest of the system running.
@MainActor
final class DeepSleepController: ObservableObject {
    private let stateMachine: StateMachine
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var spaceMonitor: Any?
    private var personCurrentlyDetected = false
    @Published private(set) var wakeInhibitUntil: Date?

    private let sleepStartHour = 19
    private let wakeHour = 7

    @Published private(set) var isDeepSleeping = false
    @Published private(set) var nextSleepAt: Date?
    @Published private(set) var nextWakeAt: Date?

    init(stateMachine: StateMachine) {
        self.stateMachine = stateMachine
    }

    func start() {
        subscribeToDetection()
        startClock()
        refreshScheduleAnchors()
        evaluateSchedule()
        installSpaceMonitor()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let monitor = spaceMonitor {
            NSEvent.removeMonitor(monitor)
        }
        spaceMonitor = nil
        cancellables.removeAll()
        wakeInhibitUntil = nil
    }

    func requestManualDeepSleep() {
        wakeInhibitUntil = Date().addingTimeInterval(15)
        enterDeepSleep(reason: "spacebar")
    }

    private func subscribeToDetection() {
        stateMachine.detectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDetection(update)
            }
            .store(in: &cancellables)
    }

    private func handleDetection(_ update: StateMachine.DetectionUpdate) {
        personCurrentlyDetected = update.personDetected
        guard isDeepSleeping else { return }
        guard update.personDetected else { return }
        guard isWakeAllowed(at: update.timestamp) else { return }
        if let inhibit = wakeInhibitUntil, update.timestamp < inhibit {
            return
        }
        exitDeepSleep(reason: "face_detected")
    }
    
    private func startClock() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.evaluateSchedule()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func evaluateSchedule(now: Date = Date()) {
        refreshScheduleAnchors(now: now)
        if isDeepSleeping, personCurrentlyDetected, isWakeAllowed(at: now) {
            if let inhibit = wakeInhibitUntil, now < inhibit {
                return
            }
            exitDeepSleep(reason: "face_detected")
        }
        guard shouldEnterDeepSleep(at: now) else { return }
        enterDeepSleep(reason: "schedule")
    }

    private func shouldEnterDeepSleep(at date: Date) -> Bool {
        guard let hour = Calendar.current.dateComponents([.hour], from: date).hour else { return false }
        return hour >= sleepStartHour || hour < wakeHour
    }

    private func isWakeAllowed(at date: Date) -> Bool {
        guard let hour = Calendar.current.dateComponents([.hour], from: date).hour else { return false }
        return hour >= wakeHour && hour < sleepStartHour
    }

    private func enterDeepSleep(reason: String) {
        guard !isDeepSleeping else { return }
        if reason != "spacebar" {
            wakeInhibitUntil = nil
        }
        isDeepSleeping = true
        print("😴 Deep sleep activated (\(reason))")
        stateMachine.send(.enterDeepSleep)
    }

    private func exitDeepSleep(reason: String) {
        guard isDeepSleeping else { return }
        isDeepSleeping = false
        wakeInhibitUntil = nil
        print("🌅 Deep sleep ended (\(reason))")
        stateMachine.send(.exitDeepSleep)
        refreshScheduleAnchors()
    }

    private func installSpaceMonitor() {
        spaceMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let isPlainSpace = event.keyCode == 49 &&
                event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
            if isPlainSpace {
                self?.requestManualDeepSleep()
            }
            return event
        }
    }

    private func refreshScheduleAnchors(now: Date = Date()) {
        nextSleepAt = nextOccurrence(ofHour: sleepStartHour, from: now)
        nextWakeAt = nextOccurrence(ofHour: wakeHour, from: now)
    }

    private func nextOccurrence(ofHour hour: Int, from date: Date) -> Date? {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.nextDate(
            after: date,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        )
    }
}
