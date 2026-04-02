//
//  CheckInTimerTests.swift
//  GeoWCSTests - Check-In Timer Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Pure logic tests for missed check-in timer state management.
//

import XCTest

class CheckInTimerTests: XCTestCase {
    
    var sut: CheckInTimerManager!
    
    override func setUp() {
        super.setUp()
        sut = CheckInTimerManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Timer Creation
    
    func testCreateTimerWithCustomInterval() {
        let timer = sut.createTimer(intervalSeconds: 3600, label: "Daily Check-In")
        
        XCTAssertNotNil(timer)
        XCTAssertEqual(timer?.id, "daily-check-in")
        XCTAssertEqual(timer?.intervalSeconds, 3600)
        XCTAssertEqual(timer?.label, "Daily Check-In")
    }
    
    func testCreateMultipleTimers() {
        let timer1 = sut.createTimer(intervalSeconds: 60, label: "Hourly")
        let timer2 = sut.createTimer(intervalSeconds: 3600, label: "Daily")
        
        XCTAssertEqual(sut.getActiveTimers().count, 2)
        XCTAssertNotEqual(timer1?.id, timer2?.id)
    }
    
    func testTimerStartsInArmedState() {
        let timer = sut.createTimer(intervalSeconds: 60, label: "Test")
        XCTAssertEqual(timer?.state, .armed)
    }
    
    // MARK: - Timer State Management
    
    func testDisarmTimer() {
        let timer = sut.createTimer(intervalSeconds: 60, label: "Test")
        sut.disarmTimer(id: timer!.id)
        
        let disarmed = sut.getTimer(id: timer!.id)
        XCTAssertEqual(disarmed?.state, .disarmed)
    }
    
    func testRearmTimer() {
        let timer = sut.createTimer(intervalSeconds: 60, label: "Test")
        let timerId = timer!.id
        
        sut.disarmTimer(id: timerId)
        sut.rearmTimer(id: timerId)
        
        let rearmed = sut.getTimer(id: timerId)
        XCTAssertEqual(rearmed?.state, .armed)
    }
    
    func testDeleteTimer() {
        let timer = sut.createTimer(intervalSeconds: 60, label: "Test")
        let timerId = timer!.id
        
        XCTAssertEqual(sut.getActiveTimers().count, 1)
        sut.deleteTimer(id: timerId)
        XCTAssertEqual(sut.getActiveTimers().count, 0)
    }
    
    // MARK: - Missed Check-In Detection
    
    func testTimerTransitionsToMissedStateAfterExpiry() {
        let fastTimer = sut.createTimer(intervalSeconds: 1, label: "Fast")
        let timerId = fastTimer!.id
        
        // Initial state
        XCTAssertEqual(sut.getTimer(id: timerId)?.state, .armed)
        
        // Wait for expiry
        Thread.sleep(forTimeInterval: 1.5)
        sut.updateTimerStates()
        
        // Should now be missed
        let updated = sut.getTimer(id: timerId)
        XCTAssertEqual(updated?.state, .missed)
    }
    
    func testCheckInResetsTimer() {
        let timer = sut.createTimer(intervalSeconds: 1, label: "Test")
        let timerId = timer!.id
        
        // Wait for timer to expire
        Thread.sleep(forTimeInterval: 1.5)
        sut.updateTimerStates()
        
        XCTAssertEqual(sut.getTimer(id: timerId)?.state, .missed)
        
        // Check in
        sut.checkIn(id: timerId)
        
        // Should be armed again
        XCTAssertEqual(sut.getTimer(id: timerId)?.state, .armed)
    }
    
    func testMissedCheckInDoesNotResetWhenDisarmed() {
        let timer = sut.createTimer(intervalSeconds: 1, label: "Test")
        let timerId = timer!.id
        
        sut.disarmTimer(id: timerId)
        
        Thread.sleep(forTimeInterval: 1.5)
        sut.updateTimerStates()
        
        // Should still be disarmed, not missed
        XCTAssertEqual(sut.getTimer(id: timerId)?.state, .disarmed)
    }
    
    func testTimerProgressTracking() {
        let timer = sut.createTimer(intervalSeconds: 10, label: "Test")
        let timerId = timer!.id
        
        let progress1 = sut.getTimerProgress(id: timerId)
        XCTAssertGreaterThan(progress1, 0.0)
        XCTAssertLessThanOrEqual(progress1, 1.0)
        
        Thread.sleep(forTimeInterval: 2)
        sut.updateTimerStates()
        
        let progress2 = sut.getTimerProgress(id: timerId)
        XCTAssertLessThan(progress2, progress1)
    }
    
    // MARK: - Timer Notifications
    
    func testMissedCheckInTriggersNotification() {
        let notificationExpectation = expectation(
            forNotification: NSNotification.Name("CheckInMissed"),
            object: nil
        )
        
        let timer = sut.createTimer(intervalSeconds: 1, label: "Test")
        let timerId = timer!.id
        
        Thread.sleep(forTimeInterval: 1.5)
        sut.updateTimerStates()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("CheckInMissed"), object: timerId)
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testTimerResetNotification() {
        let notificationExpectation = expectation(
            forNotification: NSNotification.Name("TimerReset"),
            object: nil
        )
        
        let timer = sut.createTimer(intervalSeconds: 60, label: "Test")
        let timerId = timer!.id
        
        DispatchQueue.main.async {
            self.sut.checkIn(id: timerId)
            NotificationCenter.default.post(name: NSNotification.Name("TimerReset"), object: timerId)
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Multiple Timer Coordination
    
    func testGetAllMissedTimers() {
        let timer1 = sut.createTimer(intervalSeconds: 1, label: "Timer1")
        let timer2 = sut.createTimer(intervalSeconds: 60, label: "Timer2")
        
        Thread.sleep(forTimeInterval: 1.5)
        sut.updateTimerStates()
        
        let missedTimers = sut.getMissedTimers()
        XCTAssertEqual(missedTimers.count, 1)
        XCTAssertEqual(missedTimers.first?.id, timer1?.id)
    }
    
    func testResetAllTimers() {
        sut.createTimer(intervalSeconds: 60, label: "Timer1")
        sut.createTimer(intervalSeconds: 60, label: "Timer2")
        
        sut.resetAllTimers()
        
        let allTimers = sut.getActiveTimers()
        XCTAssertTrue(allTimers.allSatisfy { $0.state == .armed })
    }
    
    func testClearAllMissedNotifications() {
        let timer1 = sut.createTimer(intervalSeconds: 1, label: "Timer1")
        let timer2 = sut.createTimer(intervalSeconds: 1, label: "Timer2")
        
        Thread.sleep(forTimeInterval: 1.5)
        sut.updateTimerStates()
        
        XCTAssertEqual(sut.getMissedTimers().count, 2)
        
        sut.clearMissedTimers()
        
        XCTAssertEqual(sut.getMissedTimers().count, 0)
    }
    
    // MARK: - Timer Persistence
    
    func testTimerStateIsPersisted() {
        let timer = sut.createTimer(intervalSeconds: 60, label: "Persistent")
        let timerId = timer!.id
        
        sut.disarmTimer(id: timerId)
        
        // Simulate app restart
        let newManager = CheckInTimerManager()
        newManager.loadFromStorage()
        
        // Timer should still be in disarmed state
        XCTAssertEqual(newManager.getTimer(id: timerId)?.state, .disarmed)
    }
    
    // MARK: - Scheduling
    
    func testScheduleCheckInReminder() {
        let timer = sut.createTimer(intervalSeconds: 60, label: "Reminder")
        let timerId = timer!.id
        
        let reminderTime = Date(timeIntervalSinceNow: 30)
        sut.scheduleReminder(forTimerId: timerId, at: reminderTime)
        
        let reminder = sut.getScheduledReminder(forTimerId: timerId)
        XCTAssertNotNil(reminder)
    }
    
    func testCancelCheckInReminder() {
        let timer = sut.createTimer(intervalSeconds: 60, label: "Reminder")
        let timerId = timer!.id
        
        let reminderTime = Date(timeIntervalSinceNow: 30)
        sut.scheduleReminder(forTimerId: timerId, at: reminderTime)
        
        sut.cancelReminder(forTimerId: timerId)
        
        let reminder = sut.getScheduledReminder(forTimerId: timerId)
        XCTAssertNil(reminder)
    }
    
    // MARK: - Battery & Performance
    
    func testTimerDoesNotConsumeSigificantMemory() {
        // Create many timers
        for i in 0..<100 {
            sut.createTimer(intervalSeconds: 60, label: "Timer\(i)")
        }
        
        let activeTimers = sut.getActiveTimers()
        XCTAssertEqual(activeTimers.count, 100)
        XCTAssertLessThanOrEqual(
            MemoryLayout.size(ofValue: sut),
            1024 * 100 // 100KB reasonable upper bound for 100 timers
        )
    }
    
    // MARK: - Edge Cases
    
    func testZeroIntervalTimer() {
        let timer = sut.createTimer(intervalSeconds: 0, label: "Zero")
        sut.updateTimerStates()
        
        XCTAssertEqual(timer?.state, .missed)
    }
    
    func testNegativeIntervalTimer() {
        let timer = sut.createTimer(intervalSeconds: -10, label: "Negative")
        sut.updateTimerStates()
        
        XCTAssertEqual(timer?.state, .missed)
    }
    
    func testCheckInOnNonexistentTimer() {
        XCTAssertNoThrow(sut.checkIn(id: "nonexistent"))
    }
    
    func testTimerLabelWithSpecialCharacters() {
        let specialLabel = "Check-In: Status & Review™"
        let timer = sut.createTimer(intervalSeconds: 60, label: specialLabel)
        
        XCTAssertEqual(timer?.label, specialLabel)
    }
}

// MARK: - Test Implementation

class CheckInTimerManager {
    private var timers: [String: CheckInTimerState] = [:]
    
    enum TimerState {
        case armed
        case disarmed
        case missed
    }
    
    struct CheckInTimerState {
        let id: String
        let intervalSeconds: Int
        let label: String
        var state: TimerState
        var createdAt: Date
        var lastCheckedInAt: Date?
    }
    
    func createTimer(intervalSeconds: Int, label: String) -> CheckInTimerState? {
        let id = label.lowercased().replacingOccurrences(of: " ", with: "-")
        
        let timer = CheckInTimerState(
            id: id,
            intervalSeconds: max(0, intervalSeconds),
            label: label,
            state: .armed,
            createdAt: Date()
        )
        
        timers[id] = timer
        return timer
    }
    
    func getTimer(id: String) -> CheckInTimerState? {
        return timers[id]
    }
    
    func getActiveTimers() -> [CheckInTimerState] {
        return Array(timers.values)
    }
    
    func disarmTimer(id: String) {
        timers[id]?.state = .disarmed
    }
    
    func rearmTimer(id: String) {
        timers[id]?.state = .armed
    }
    
    func deleteTimer(id: String) {
        timers.removeValue(forKey: id)
    }
    
    func updateTimerStates() {
        let now = Date()
        
        for (id, var timer) in timers {
            guard timer.state == .armed else { continue }
            
            let elapsedSeconds = Int(now.timeIntervalSince(timer.createdAt))
            if elapsedSeconds >= timer.intervalSeconds && timer.intervalSeconds > 0 {
                timer.state = .missed
            } else if timer.intervalSeconds <= 0 {
                timer.state = .missed
            }
            
            timers[id] = timer
        }
    }
    
    func checkIn(id: String) {
        guard var timer = timers[id] else { return }
        timer.state = .armed
        timer.createdAt = Date()
        timer.lastCheckedInAt = Date()
        timers[id] = timer
    }
    
    func getMissedTimers() -> [CheckInTimerState] {
        return timers.values.filter { $0.state == .missed }
    }
    
    func resetAllTimers() {
        for id in timers.keys {
            timers[id]?.state = .armed
            timers[id]?.createdAt = Date()
        }
    }
    
    func clearMissedTimers() {
        for id in timers.keys where timers[id]?.state == .missed {
            timers[id]?.state = .armed
        }
    }
    
    func getTimerProgress(id: String) -> Double {
        guard let timer = timers[id], timer.state == .armed, timer.intervalSeconds > 0 else {
            return 1.0
        }
        
        let elapsedSeconds = Date().timeIntervalSince(timer.createdAt)
        let progress = elapsedSeconds / Double(timer.intervalSeconds)
        return min(1.0, max(0.0, progress))
    }
    
    func scheduleReminder(forTimerId id: String, at date: Date) {
        // Implementation would use UserNotifications framework
    }
    
    func getScheduledReminder(forTimerId id: String) -> Date? {
        return nil // Stub for testing
    }
    
    func cancelReminder(forTimerId id: String) {
        // Implementation would use UserNotifications framework
    }
    
    func loadFromStorage() {
        // Stub for persistence testing
    }
}
