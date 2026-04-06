//
//  PatientProfile.swift
//  DementiaMedia – Domain Layer
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  A value-type representation of a patient in the dementia-care context.
//  Contains no UI, no framework imports, and no persistence details.
//

import Foundation

/// Cognitive support level affects which features are visible
/// and how timeouts, prompts, and confirmations are configured.
public enum CognitiveSupportLevel: Int, Codable, Sendable {
    case independent = 0
    case guided      = 1
    case supervised  = 2
}

/// The stable identity and preference record for one dementia patient.
public struct PatientProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var displayName: String
    public var dateOfBirth: Date
    public var supportLevel: CognitiveSupportLevel
    public var accessibilityProfile: AccessibilityProfile
    public var caregiverID: UUID?

    public init(
        id: UUID = .init(),
        displayName: String,
        dateOfBirth: Date,
        supportLevel: CognitiveSupportLevel = .guided,
        accessibilityProfile: AccessibilityProfile = .default,
        caregiverID: UUID? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.dateOfBirth = dateOfBirth
        self.supportLevel = supportLevel
        self.accessibilityProfile = accessibilityProfile
        self.caregiverID = caregiverID
    }
}
