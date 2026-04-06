//
//  AccessibilityProfile.swift
//  DementiaMedia – Domain Layer
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Per-patient accessibility preferences that drive UI layout and
//  media-feature behaviour. Pure value type; no UIKit/SwiftUI dependency.
//

import Foundation

/// Contrast modes that can be requested regardless of system setting.
public enum ContrastMode: String, Codable, Sendable {
    case system, high, veryHigh
}

/// Voice speed expressed as a multiplier (0.25 – 2.0).
public typealias VoiceSpeedMultiplier = Double

/// Consolidated accessibility preferences for one patient.
public struct AccessibilityProfile: Codable, Equatable, Sendable {

    /// Minimum tap/touch target side length in points (44 pt baseline).
    public var minimumTapTargetPts: Double
    /// Preferred font scale multiplier applied on top of Dynamic Type.
    public var fontScaleMultiplier: Double
    /// Contrast mode preference.
    public var contrastMode: ContrastMode
    /// Whether the UI should use simplified layouts (fewer visible options).
    public var simplifiedLayout: Bool
    /// Preferred TTS playback speed; 1.0 = normal.
    public var voiceSpeed: VoiceSpeedMultiplier
    /// Whether the painting canvas should show an oversized brush by default.
    public var useLargeBrushByDefault: Bool
    /// Whether haptic feedback is enabled.
    public var hapticFeedbackEnabled: Bool

    /// Sensible defaults for a supervised patient.
    public static let `default` = AccessibilityProfile(
        minimumTapTargetPts: 60,
        fontScaleMultiplier: 1.3,
        contrastMode: .high,
        simplifiedLayout: true,
        voiceSpeed: 0.85,
        useLargeBrushByDefault: true,
        hapticFeedbackEnabled: true
    )

    public init(
        minimumTapTargetPts: Double = 60,
        fontScaleMultiplier: Double = 1.3,
        contrastMode: ContrastMode = .high,
        simplifiedLayout: Bool = true,
        voiceSpeed: VoiceSpeedMultiplier = 0.85,
        useLargeBrushByDefault: Bool = true,
        hapticFeedbackEnabled: Bool = true
    ) {
        self.minimumTapTargetPts = minimumTapTargetPts
        self.fontScaleMultiplier = fontScaleMultiplier
        self.contrastMode = contrastMode
        self.simplifiedLayout = simplifiedLayout
        self.voiceSpeed = voiceSpeed
        self.useLargeBrushByDefault = useLargeBrushByDefault
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
    }
}
