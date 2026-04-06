//
//  Policies.swift
//  DementiaMedia – Domain Layer / Policies
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  First-class policy objects for dementia-safety, accessibility,
//  emotional safety, privacy, storage, and performance.  Tests for
//  these live in the dedicated quality-suite test files.
//  No framework imports – pure Swift value types.
//

import Foundation

// MARK: - StorageThresholdPolicy

/// Governs app behaviour when device storage is low.
public struct StorageThresholdPolicy: Equatable, Sendable {

    /// Bytes remaining below which draft saves are blocked (default: 50 MB).
    public var draftBlockThresholdBytes: Int64
    /// Bytes remaining below which exports are blocked (default: 200 MB).
    public var exportBlockThresholdBytes: Int64
    /// Bytes remaining that trigger a user-visible low-storage warning (default: 500 MB).
    public var warningThresholdBytes: Int64

    public static let `default` = StorageThresholdPolicy(
        draftBlockThresholdBytes: 50 * 1_024 * 1_024,
        exportBlockThresholdBytes: 200 * 1_024 * 1_024,
        warningThresholdBytes: 500 * 1_024 * 1_024
    )

    public init(
        draftBlockThresholdBytes: Int64,
        exportBlockThresholdBytes: Int64,
        warningThresholdBytes: Int64
    ) {
        self.draftBlockThresholdBytes = draftBlockThresholdBytes
        self.exportBlockThresholdBytes = exportBlockThresholdBytes
        self.warningThresholdBytes = warningThresholdBytes
    }

    public func shouldBlockDraft(freeBytes: Int64) -> Bool {
        freeBytes < draftBlockThresholdBytes
    }

    public func shouldBlockExport(freeBytes: Int64) -> Bool {
        freeBytes < exportBlockThresholdBytes
    }

    public func shouldWarn(freeBytes: Int64) -> Bool {
        freeBytes < warningThresholdBytes
    }
}

// MARK: - CognitiveSafetyPolicy

/// Enforces one-primary-action-per-screen and limited simultaneous choices.
public struct CognitiveSafetyPolicy: Equatable, Sendable {

    /// Maximum number of selectable options shown at once.
    public var maximumSimultaneousChoices: Int
    /// Maximum number of distinct interactive controls per screen.
    public var maximumInteractiveControlsPerScreen: Int
    /// Whether navigation back is always visible.
    public var backAlwaysVisible: Bool
    /// Whether error messages use plain language (no technical jargon).
    public var plainLanguageErrors: Bool

    public static let dementiaSafe = CognitiveSafetyPolicy(
        maximumSimultaneousChoices: 3,
        maximumInteractiveControlsPerScreen: 4,
        backAlwaysVisible: true,
        plainLanguageErrors: true
    )

    public init(
        maximumSimultaneousChoices: Int,
        maximumInteractiveControlsPerScreen: Int,
        backAlwaysVisible: Bool,
        plainLanguageErrors: Bool
    ) {
        self.maximumSimultaneousChoices = maximumSimultaneousChoices
        self.maximumInteractiveControlsPerScreen = maximumInteractiveControlsPerScreen
        self.backAlwaysVisible = backAlwaysVisible
        self.plainLanguageErrors = plainLanguageErrors
    }

    public func isSafe(choiceCount: Int) -> Bool {
        choiceCount <= maximumSimultaneousChoices
    }

    public func isSafe(controlCount: Int) -> Bool {
        controlCount <= maximumInteractiveControlsPerScreen
    }
}

// MARK: - EmotionalSafetyPolicy

/// Prevents distressing UX patterns for patients with dementia.
public struct EmotionalSafetyPolicy: Equatable, Sendable {

    /// Seconds of silence before any audio begins (prevents sudden autoplay).
    public var minimumAutoplaySilenceSeconds: Double
    /// Whether delete confirmations are required before any media is removed.
    public var requireDeleteConfirmation: Bool
    /// Whether alarm-tone notifications are forbidden (should use gentle tones).
    public var forbidAlarmTones: Bool
    /// Whether dead-end permission states are forbidden (must offer guidance).
    public var mustProvidePermissionRecovery: Bool

    public static let `default` = EmotionalSafetyPolicy(
        minimumAutoplaySilenceSeconds: 1.5,
        requireDeleteConfirmation: true,
        forbidAlarmTones: true,
        mustProvidePermissionRecovery: true
    )

    public init(
        minimumAutoplaySilenceSeconds: Double,
        requireDeleteConfirmation: Bool,
        forbidAlarmTones: Bool,
        mustProvidePermissionRecovery: Bool
    ) {
        self.minimumAutoplaySilenceSeconds = minimumAutoplaySilenceSeconds
        self.requireDeleteConfirmation = requireDeleteConfirmation
        self.forbidAlarmTones = forbidAlarmTones
        self.mustProvidePermissionRecovery = mustProvidePermissionRecovery
    }

    /// Returns `true` if a delay value meets the minimum silence requirement.
    public func isAutoplaySafe(delaySeconds: Double) -> Bool {
        delaySeconds >= minimumAutoplaySilenceSeconds
    }
}

// MARK: - PrivacyConsentPolicy

/// Governs consent, caregiver permissions, and media export restrictions.
public struct PrivacyConsentPolicy: Equatable, Sendable {

    /// Whether explicit patient or caregiver consent is required before recording.
    public var requiresExplicitRecordingConsent: Bool
    /// Whether media can be exported to non-app destinations (AirDrop, Files).
    public var allowsExternalExport: Bool
    /// Whether media is stored exclusively on-device (no cloud sync even if iCloud is on).
    public var enforceLocalOnlyStorage: Bool
    /// Whether a secondary confirmation is required to permanently delete media.
    public var requiresDeletionConfirmation: Bool

    public static let `default` = PrivacyConsentPolicy(
        requiresExplicitRecordingConsent: true,
        allowsExternalExport: false,
        enforceLocalOnlyStorage: true,
        requiresDeletionConfirmation: true
    )

    public init(
        requiresExplicitRecordingConsent: Bool,
        allowsExternalExport: Bool,
        enforceLocalOnlyStorage: Bool,
        requiresDeletionConfirmation: Bool
    ) {
        self.requiresExplicitRecordingConsent = requiresExplicitRecordingConsent
        self.allowsExternalExport = allowsExternalExport
        self.enforceLocalOnlyStorage = enforceLocalOnlyStorage
        self.requiresDeletionConfirmation = requiresDeletionConfirmation
    }
}

// MARK: - PerformanceBudgetPolicy

/// Latency budgets used by performance tests (all values in seconds).
public struct PerformanceBudgetPolicy: Equatable, Sendable {

    public var maxColdLaunchSeconds: Double
    public var maxPaintingFirstStrokeLatencySeconds: Double
    public var maxRecordStartLatencySeconds: Double
    public var maxPreviewLoadLatencySeconds: Double
    public var maxSlideshowExportSeconds: Double   // for ≤ 10 images at 1fps
    public var maxLibraryScrollFPS: Double          // minimum acceptable FPS

    public static let acceptable = PerformanceBudgetPolicy(
        maxColdLaunchSeconds: 2.0,
        maxPaintingFirstStrokeLatencySeconds: 0.033,   // one frame at 30fps
        maxRecordStartLatencySeconds: 0.5,
        maxPreviewLoadLatencySeconds: 1.0,
        maxSlideshowExportSeconds: 30.0,
        maxLibraryScrollFPS: 55.0
    )

    public init(
        maxColdLaunchSeconds: Double,
        maxPaintingFirstStrokeLatencySeconds: Double,
        maxRecordStartLatencySeconds: Double,
        maxPreviewLoadLatencySeconds: Double,
        maxSlideshowExportSeconds: Double,
        maxLibraryScrollFPS: Double
    ) {
        self.maxColdLaunchSeconds = maxColdLaunchSeconds
        self.maxPaintingFirstStrokeLatencySeconds = maxPaintingFirstStrokeLatencySeconds
        self.maxRecordStartLatencySeconds = maxRecordStartLatencySeconds
        self.maxPreviewLoadLatencySeconds = maxPreviewLoadLatencySeconds
        self.maxSlideshowExportSeconds = maxSlideshowExportSeconds
        self.maxLibraryScrollFPS = maxLibraryScrollFPS
    }
}
