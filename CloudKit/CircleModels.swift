//
//  CircleMember.swift
//  GeoWCS - Circle Membership Model
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Represents a member in a safety circle with phone validation.
//

import Foundation
import CloudKit

struct CircleMember: Identifiable, Codable {
    let id: String
    let name: String
    let phoneNumber: String // Validated E.164 format
    let role: Role
    let joinedAt: Date
    let lastSeenAt: Date?
    let isActive: Bool
    let deviceTokens: [String] // For push notifications
    
    enum Role: String, Codable {
        case creator = "Creator"
        case admin = "Admin"
        case member = "Member"
    }
    
    // MARK: - Initialization
    
    /// Initialize circle member with phone validation
    init(
        name: String,
        phoneNumber: String,
        role: Role = .member,
        joinedAt: Date = Date()
    ) throws {
        // Validate phone number
        let validatedPhone = try PhoneNumberValidator.validate(phoneNumber)
        
        self.id = UUID().uuidString
        self.name = name.trimmingCharacters(in: .whitespaces)
        self.phoneNumber = validatedPhone
        self.role = role
        self.joinedAt = joinedAt
        self.lastSeenAt = nil
        self.isActive = true
        self.deviceTokens = []
        
        // Validate name
        guard !self.name.isEmpty else {
            throw CircleMemberError.invalidName
        }
        
        guard self.name.count >= 2 else {
            throw CircleMemberError.nameTooShort
        }
        
        guard self.name.count <= 50 else {
            throw CircleMemberError.nameTooLong
        }
    }
    
    // MARK: - Update Methods
    
    mutating func updateLastSeen() {
        self.lastSeenAt = Date()
    }
    
    mutating func addDeviceToken(_ token: String) {
        if !deviceTokens.contains(token) {
            deviceTokens.append(token)
        }
    }
    
    mutating func removeDeviceToken(_ token: String) {
        deviceTokens.removeAll { $0 == token }
    }
    
    // MARK: - Validation
    
    var isPhoneValid: Bool {
        PhoneNumberValidator.isValid(phoneNumber)
    }
    
    var countryFromPhone: String? {
        PhoneNumberValidator.suggestCountry(phoneNumber)
    }
}

// MARK: - Error Types

enum CircleMemberError: LocalizedError {
    case invalidName
    case nameTooShort
    case nameTooLong
    case invalidPhoneNumber
    case duplicateMember
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Name cannot be empty"
        case .nameTooShort:
            return "Name must be at least 2 characters"
        case .nameTooLong:
            return "Name cannot exceed 50 characters"
        case .invalidPhoneNumber:
            return "Phone number is invalid"
        case .duplicateMember:
            return "Member with this phone already exists"
        }
    }
}

// MARK: - Circle Model

struct Circle: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let creatorId: String
    let members: [CircleMember]
    let createdAt: Date
    let updatedAt: Date
    let maxMembers: Int
    let isPrivate: Bool
    
    // MARK: - Initialization
    
    init(
        name: String,
        description: String? = nil,
        creatorId: String,
        maxMembers: Int = 10,
        isPrivate: Bool = true
    ) throws {
        guard !name.isEmpty && name.count >= 2 && name.count <= 100 else {
            throw CircleError.invalidName
        }
        
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.creatorId = creatorId
        self.members = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.maxMembers = maxMembers
        self.isPrivate = isPrivate
    }
    
    // MARK: - Member Management
    
    /// Add member with phone validation
    mutating func addMember(
        name: String,
        phoneNumber: String,
        role: CircleMember.Role = .member
    ) throws {
        // Check capacity
        guard members.count < maxMembers else {
            throw CircleError.maxMembersReached
        }
        
        // Create validated member
        let newMember = try CircleMember(
            name: name,
            phoneNumber: phoneNumber,
            role: role
        )
        
        // Check for duplicates
        if members.contains(where: { $0.phoneNumber == newMember.phoneNumber }) {
            throw CircleError.memberAlreadyExists
        }
        
        members.append(newMember)
        updatedAt = Date()
    }
    
    /// Remove member by phone number
    mutating func removeMember(byPhoneNumber phoneNumber: String) throws {
        let validatedPhone = try PhoneNumberValidator.validate(phoneNumber)
        
        guard let index = members.firstIndex(where: { $0.phoneNumber == validatedPhone }) else {
            throw CircleError.memberNotFound
        }
        
        members.remove(at: index)
        updatedAt = Date()
    }
    
    /// Find member by phone number
    func findMember(byPhoneNumber phoneNumber: String) throws -> CircleMember? {
        let validatedPhone = try PhoneNumberValidator.validate(phoneNumber)
        return members.first { $0.phoneNumber == validatedPhone }
    }
    
    /// Get member count
    var memberCount: Int {
        members.count
    }
    
    /// Check if circle is full
    var isFull: Bool {
        members.count >= maxMembers
    }
    
    /// Get available slots
    var availableSlots: Int {
        max(0, maxMembers - members.count)
    }
}

// MARK: - Circle Error Types

enum CircleError: LocalizedError {
    case invalidName
    case maxMembersReached
    case memberAlreadyExists
    case memberNotFound
    case invalidRole
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Circle name must be between 2-100 characters"
        case .maxMembersReached:
            return "Circle has reached maximum member capacity"
        case .memberAlreadyExists:
            return "Member with this phone number already exists in circle"
        case .memberNotFound:
            return "Member not found in circle"
        case .invalidRole:
            return "Invalid member role"
        }
    }
}
