//
//  ActivitySession.swift
//  DementiaMedia – Domain Layer
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Models one patient's run through a guided activity.  The session
//  owns a sequence of steps and enforces fatigue-aware pacing,
//  caregiver-override rules, and completion logic.  No UIKit/AppKit
//  or framework import – pure Swift value types only.
//

import Foundation

// MARK: - ActivityStep

/// One small, self-contained instruction within an activity.
public struct ActivityStep: Identifiable, Codable, Equatable, Sendable {

    public enum State: String, Codable, Equatable, Sendable {
        case pending
        case active
        case completed
        case skipped
    }

    public let id: UUID
    /// Short instruction shown to the patient (≤ 120 chars recommended).
    public var instruction: String
    /// Optional URL of an audio file that reads the instruction aloud.
    public var audioGuidanceURL: URL?
    /// Optional URL of an illustrative image.
    public var illustrationURL: URL?
    /// Estimated seconds the patient needs to complete this step.
    public var estimatedDurationSeconds: Double
    /// Whether a caregiver may skip this step on the patient's behalf.
    public var caregiverSkippable: Bool
    public var state: State

    public init(
        id: UUID = .init(),
        instruction: String,
        audioGuidanceURL: URL? = nil,
        illustrationURL: URL? = nil,
        estimatedDurationSeconds: Double = 60,
        caregiverSkippable: Bool = true,
        state: State = .pending
    ) {
        self.id = id
        self.instruction = instruction
        self.audioGuidanceURL = audioGuidanceURL
        self.illustrationURL = illustrationURL
        self.estimatedDurationSeconds = estimatedDurationSeconds
        self.caregiverSkippable = caregiverSkippable
        self.state = state
    }
}

// MARK: - FatiguePacingPolicy

/// Domain-level rules for spacing step presentation.
public struct FatiguePacingPolicy: Codable, Equatable, Sendable {

    /// Seconds to rest before automatically revealing the next step.
    public var restIntervalSeconds: Double
    /// Maximum steps shown in one sitting before a mandatory break.
    public var maxStepsPerBlock: Int
    /// Whether the session pauses automatically after `maxStepsPerBlock`.
    public var enforceAutoBreak: Bool

    /// Conservative default suitable for moderate cognitive impairment.
    public static let standard = FatiguePacingPolicy(
        restIntervalSeconds: 10,
        maxStepsPerBlock: 5,
        enforceAutoBreak: true
    )

    /// Lighter pacing for independent-level patients.
    public static let relaxed = FatiguePacingPolicy(
        restIntervalSeconds: 5,
        maxStepsPerBlock: 10,
        enforceAutoBreak: false
    )

    public init(restIntervalSeconds: Double, maxStepsPerBlock: Int, enforceAutoBreak: Bool) {
        self.restIntervalSeconds = restIntervalSeconds
        self.maxStepsPerBlock = maxStepsPerBlock
        self.enforceAutoBreak = enforceAutoBreak
    }
}

// MARK: - SessionState

public enum SessionState: String, Codable, Equatable, Sendable {
    case notStarted
    case inProgress
    case pausedForBreak   // automatic fatigue break
    case pausedByCaregiver
    case completed
    case abandoned
}

// MARK: - SessionSummary

/// Immutable snapshot produced when a session reaches a terminal state.
public struct SessionSummary: Codable, Equatable, Sendable {
    public let sessionID: UUID
    public let patientID: UUID
    public let promptTitle: String
    public let totalSteps: Int
    public let completedSteps: Int
    public let skippedSteps: Int
    public let durationSeconds: Double
    public let completedAt: Date

    public var completionRate: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(completedSteps) / Double(totalSteps)
    }
}

// MARK: - ActivitySession

/// Tracks one patient's run through a guided activity.
public struct ActivitySession: Identifiable, Codable, Equatable, Sendable {

    public let id: UUID
    public let patientID: UUID
    /// Title of the originating `ActivityPrompt`.
    public let promptTitle: String
    public private(set) var steps: [ActivityStep]
    public private(set) var state: SessionState
    public private(set) var currentStepIndex: Int
    public var pacingPolicy: FatiguePacingPolicy
    public var startedAt: Date?
    public var endedAt: Date?
    /// Steps completed since the last fatigue break.
    public private(set) var stepsInCurrentBlock: Int
    /// Caregiver who approved skipping, if any (free-form ID string).
    public private(set) var caregiverOverrideID: String?

    // MARK: Computed

    public var currentStep: ActivityStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    public var isTerminal: Bool {
        state == .completed || state == .abandoned
    }

    public var pendingStepCount: Int {
        steps.filter { $0.state == .pending }.count
    }

    public var completedStepCount: Int {
        steps.filter { $0.state == .completed }.count
    }

    // MARK: Init

    public init(
        id: UUID = .init(),
        patientID: UUID,
        promptTitle: String,
        steps: [ActivityStep],
        pacingPolicy: FatiguePacingPolicy = .standard,
        state: SessionState = .notStarted,
        currentStepIndex: Int = 0,
        stepsInCurrentBlock: Int = 0,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        caregiverOverrideID: String? = nil
    ) {
        self.id = id
        self.patientID = patientID
        self.promptTitle = promptTitle
        self.steps = steps
        self.pacingPolicy = pacingPolicy
        self.state = state
        self.currentStepIndex = currentStepIndex
        self.stepsInCurrentBlock = stepsInCurrentBlock
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.caregiverOverrideID = caregiverOverrideID
    }

    // MARK: Mutations

    public mutating func start(at date: Date = .init()) {
        guard state == .notStarted else { return }
        state = .inProgress
        startedAt = date
        activateCurrentStep()
    }

    /// Marks the current step complete and advances to the next.
    /// Returns `true` if the block limit was reached and an auto-break was triggered.
    @discardableResult
    public mutating func completeCurrentStep(at date: Date = .init()) -> Bool {
        guard state == .inProgress, currentStepIndex < steps.count else { return false }
        steps[currentStepIndex].state = .completed
        stepsInCurrentBlock += 1

        let autoBreakTriggered = pacingPolicy.enforceAutoBreak
            && stepsInCurrentBlock >= pacingPolicy.maxStepsPerBlock

        advance(at: date)

        if autoBreakTriggered && !isTerminal {
            state = .pausedForBreak
            stepsInCurrentBlock = 0
        }

        return autoBreakTriggered
    }

    /// Caregiver skips the current step.  Returns `false` if the step is not skippable.
    @discardableResult
    public mutating func skipCurrentStep(caregiverID: String, at date: Date = .init()) -> Bool {
        guard state == .inProgress || state == .pausedByCaregiver,
              currentStepIndex < steps.count,
              steps[currentStepIndex].caregiverSkippable else { return false }
        steps[currentStepIndex].state = .skipped
        caregiverOverrideID = caregiverID
        advance(at: date)
        return true
    }

    public mutating func pauseByCaregiver() {
        guard state == .inProgress else { return }
        state = .pausedByCaregiver
    }

    public mutating func resumeFromBreak(at date: Date = .init()) {
        guard state == .pausedForBreak || state == .pausedByCaregiver else { return }
        state = .inProgress
        activateCurrentStep()
    }

    public mutating func abandon(at date: Date = .init()) {
        guard !isTerminal else { return }
        state = .abandoned
        endedAt = date
    }

    public func makeSummary(at date: Date = .init()) -> SessionSummary? {
        guard isTerminal, let start = startedAt else { return nil }
        return SessionSummary(
            sessionID: id,
            patientID: patientID,
            promptTitle: promptTitle,
            totalSteps: steps.count,
            completedSteps: completedStepCount,
            skippedSteps: steps.filter { $0.state == .skipped }.count,
            durationSeconds: (endedAt ?? date).timeIntervalSince(start),
            completedAt: endedAt ?? date
        )
    }

    // MARK: Private helpers

    private mutating func activateCurrentStep() {
        guard currentStepIndex < steps.count else { return }
        steps[currentStepIndex].state = .active
    }

    private mutating func advance(at date: Date) {
        let next = currentStepIndex + 1
        if next >= steps.count {
            state = .completed
            endedAt = date
        } else {
            currentStepIndex = next
            if state == .inProgress { activateCurrentStep() }
        }
    }
}
