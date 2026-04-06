//
//  StartGuidedActivity.swift
//  DementiaMedia – Use Cases
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Orchestrates the full lifecycle of one patient guided-activity session:
//  look up the prompt, build an ActivitySession, persist progress, and
//  produce a SessionSummary on completion.
//

import Foundation

// MARK: - Analytics Port (declared here to stay in scope)

/// Thin port for logging activity analytics without framework coupling.
public protocol ActivityAnalyticsLogging: AnyObject {
    func log(event: String, sessionID: UUID, metadata: [String: String])
}

// MARK: - Errors

public enum GuidedActivityError: Error, Equatable {
    case promptNotFound(id: UUID)
    case sessionAlreadyTerminal
    case stepNotSkippable(stepIndex: Int)
    case persistenceFailure(underlying: String)
}

// MARK: - StartGuidedActivity

/// Starts, advances, and finalises a guided-activity session.
public final class StartGuidedActivity {

    private let repository: MediaRepository
    private let notificationScheduler: NotificationScheduling
    private let analytics: ActivityAnalyticsLogging

    public init(
        repository: MediaRepository,
        notificationScheduler: NotificationScheduling,
        analytics: ActivityAnalyticsLogging
    ) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.analytics = analytics
    }

    // MARK: - Start

    /// Creates a new session from the given `ActivityPrompt` and persists the initial state.
    /// Returns the newly created `ActivitySession`.
    public func begin(
        prompt: ActivityPrompt,
        patientID: UUID,
        pacingPolicy: FatiguePacingPolicy = .standard
    ) async throws -> ActivitySession {

        let steps = prompt.textChunks().map { chunk in
            ActivityStep(
                instruction: chunk,
                estimatedDurationSeconds: Double(prompt.estimatedMinutes ?? 3) * 60
                    / Double(max(prompt.textChunks().count, 1)),
                caregiverSkippable: true
            )
        }

        var session = ActivitySession(
            patientID: patientID,
            promptTitle: prompt.title,
            steps: steps,
            pacingPolicy: pacingPolicy
        )
        session.start()

        let asset = MediaAsset(
            ownerID: patientID,
            kind: .activitySession,
            localURL: nil,
            state: .draft
        )
        do {
            try await repository.save(asset)
        } catch {
            throw GuidedActivityError.persistenceFailure(underlying: error.localizedDescription)
        }

        analytics.log(
            event: "activity.started",
            sessionID: session.id,
            metadata: ["promptTitle": prompt.title]
        )

        return session
    }

    // MARK: - Advance

    /// Marks the current step complete and returns the updated session.
    /// Caller is responsible for re-persisting if needed.
    public func completeStep(in session: inout ActivitySession) throws {
        guard !session.isTerminal else { throw GuidedActivityError.sessionAlreadyTerminal }
        let autoBreak = session.completeCurrentStep()
        analytics.log(
            event: autoBreak ? "activity.auto_break" : "activity.step_completed",
            sessionID: session.id,
            metadata: ["stepIndex": "\(session.currentStepIndex)"]
        )
        if session.isTerminal {
            analytics.log(event: "activity.completed", sessionID: session.id, metadata: [:])
        }
    }

    // MARK: - Caregiver Skip

    /// Caregiver skips the current step.
    public func skipStep(
        in session: inout ActivitySession,
        caregiverID: String
    ) throws {
        guard !session.isTerminal else { throw GuidedActivityError.sessionAlreadyTerminal }
        let skipped = session.skipCurrentStep(caregiverID: caregiverID)
        if !skipped {
            throw GuidedActivityError.stepNotSkippable(stepIndex: session.currentStepIndex)
        }
        analytics.log(
            event: "activity.step_skipped_by_caregiver",
            sessionID: session.id,
            metadata: ["caregiverID": caregiverID]
        )
    }

    // MARK: - Resume from Break

    public func resume(session: inout ActivitySession) {
        session.resumeFromBreak()
        analytics.log(event: "activity.resumed", sessionID: session.id, metadata: [:])
    }

    // MARK: - Abandon

    public func abandon(session: inout ActivitySession) {
        session.abandon()
        analytics.log(event: "activity.abandoned", sessionID: session.id, metadata: [:])
    }

    // MARK: - Finalise

    /// Produces a `SessionSummary` and schedules a completion reminder notification.
    public func finalise(session: ActivitySession) async throws -> SessionSummary {
        guard let summary = session.makeSummary() else {
            throw GuidedActivityError.sessionAlreadyTerminal
        }
        try await notificationScheduler.scheduleActivityCompletion(
            patientID: session.patientID,
            title: session.promptTitle,
            completedAt: summary.completedAt
        )
        return summary
    }
}
