//
//  PhoneNumberValidator.swift
//  GeoWCS - Phone Number Validation
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Validates phone numbers for third-party circle members using E.164 format.
//

import Foundation
import RegexBuilder

enum PhoneValidationError: LocalizedError {
    case invalidFormat
    case invalidCountryCode
    case tooShort
    case tooLong
    case invalidCharacters
    case emptyInput

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Phone number must be in E.164 format (e.g., +14155552671)"
        case .invalidCountryCode:
            return "Country code not recognized"
        case .tooShort:
            return "Phone number is too short (minimum 10 digits)"
        case .tooLong:
            return "Phone number is too long (maximum 15 digits)"
        case .invalidCharacters:
            return "Phone number contains invalid characters"
        case .emptyInput:
            return "Phone number cannot be empty"
        }
    }
}

struct PhoneNumberValidator {
    
    // MARK: - Supported Countries
    
    private static let countryDialCodes: [String: String] = [
        "+1": "United States/Canada",
        "+44": "United Kingdom",
        "+33": "France",
        "+49": "Germany",
        "+39": "Italy",
        "+34": "Spain",
        "+61": "Australia",
        "+81": "Japan",
        "+86": "China",
        "+91": "India",
        "+55": "Brazil",
        "+27": "South Africa",
        "+7": "Russia",
        "+966": "Saudi Arabia",
        "+971": "UAE",
        "+65": "Singapore",
        "+60": "Malaysia",
        "+82": "South Korea",
        "+64": "New Zealand",
        "+31": "Netherlands",
    ]
    
    // MARK: - Validation Methods
    
    /// Validate phone number in E.164 format
    /// Examples: +1415555267, +441632960000, +33123456789
    static func validate(_ phoneNumber: String) throws -> String {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespaces)
        
        // Check for empty input
        guard !trimmed.isEmpty else {
            throw PhoneValidationError.emptyInput
        }
        
        // Check if starts with +
        guard trimmed.hasPrefix("+") else {
            throw PhoneValidationError.invalidFormat
        }
        
        // Check for only digits and +
        let validCharacters = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "+"))
        guard trimmed.allSatisfy({ String($0).rangeOfCharacter(from: validCharacters) != nil }) else {
            throw PhoneValidationError.invalidCharacters
        }
        
        // Extract digits only (remove +)
        let digitsOnly = String(trimmed.dropFirst())
        
        // Check length (10-15 digits per E.164)
        guard digitsOnly.count >= 10 else {
            throw PhoneValidationError.tooShort
        }
        
        guard digitsOnly.count <= 15 else {
            throw PhoneValidationError.tooLong
        }
        
        // Validate country code
        let countryCode = extractCountryCode(from: trimmed)
        guard countryDialCodes[countryCode] != nil else {
            throw PhoneValidationError.invalidCountryCode
        }
        
        return trimmed
    }
    
    /// Validate phone number and return formatted version
    static func validateAndFormat(_ phoneNumber: String) throws -> String {
        let validated = try validate(phoneNumber)
        return formatPhoneNumber(validated)
    }
    
    /// Check if phone number is valid without throwing
    static func isValid(_ phoneNumber: String) -> Bool {
        do {
            _ = try validate(phoneNumber)
            return true
        } catch {
            return false
        }
    }
    
    /// Suggest country from phone number
    static func suggestCountry(_ phoneNumber: String) -> String? {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespaces)
        let countryCode = extractCountryCode(from: trimmed)
        return countryDialCodes[countryCode]
    }
    
    // MARK: - Private Methods
    
    /// Extract country code from E.164 phone number
    private static func extractCountryCode(from phoneNumber: String) -> String {
        // Try 3-digit country codes first (e.g., +966, +971)
        if phoneNumber.count >= 5 {
            let threeDigitCode = String(phoneNumber.prefix(4)) // +XXX
            if countryDialCodes[threeDigitCode] != nil {
                return threeDigitCode
            }
        }
        
        // Then try 2-digit country codes (e.g., +1, +44)
        if phoneNumber.count >= 3 {
            let twoDigitCode = String(phoneNumber.prefix(3)) // +XX
            if countryDialCodes[twoDigitCode] != nil {
                return twoDigitCode
            }
        }
        
        // Fallback to longest prefix match
        for i in (2...4).reversed() {
            let prefix = String(phoneNumber.prefix(i))
            if countryDialCodes[prefix] != nil {
                return prefix
            }
        }
        
        return "+"
    }
    
    /// Format phone number for display
    private static func formatPhoneNumber(_ phoneNumber: String) -> String {
        let digitsOnly = String(phoneNumber.dropFirst()) // Remove +
        
        // Format based on length
        if digitsOnly.count == 10 {
            // US: (XXX) XXX-XXXX
            let groups = (
                String(digitsOnly.prefix(3)),
                String(digitsOnly.dropFirst(3).prefix(3)),
                String(digitsOnly.dropFirst(6))
            )
            return "+1 (\(groups.0)) \(groups.1)-\(groups.2)"
        }
        
        if digitsOnly.count == 11 {
            // International: +X XXX XXX XXXX
            let groups = (
                String(digitsOnly.prefix(1)),
                String(digitsOnly.dropFirst(1).prefix(3)),
                String(digitsOnly.dropFirst(4).prefix(3)),
                String(digitsOnly.dropFirst(7))
            )
            return "+\(groups.0) \(groups.1) \(groups.2) \(groups.3)"
        }
        
        // Generic: +XXX XXXXXXX...
        return "+" + digitsOnly
    }
    
    /// Get all supported country codes
    static func getSupportedCountryCodes() -> [String] {
        return Array(countryDialCodes.keys).sorted()
    }
    
    /// Get country info
    static func getCountryInfo(for countryCode: String) -> (code: String, name: String)? {
        if let name = countryDialCodes[countryCode] {
            return (code: countryCode, name: name)
        }
        return nil
    }
}
