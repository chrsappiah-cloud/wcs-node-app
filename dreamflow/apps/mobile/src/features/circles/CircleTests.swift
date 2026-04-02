//
//  PhoneValidatorTests.swift
//  GeoWCSTests - Phone Validation Test Suite
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Comprehensive test suite for phone number validation.
//

import XCTest

class PhoneValidatorTests: XCTestCase {
    
    // MARK: - Valid Phone Numbers
    
    func testValidUSPhoneNumber() throws {
        let validPhone = "+14155552671"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    func testValidCanadianPhoneNumber() throws {
        let validPhone = "+14165551234"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    func testValidUKPhoneNumber() throws {
        let validPhone = "+441632960000"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    func testValidGermanPhoneNumber() throws {
        let validPhone = "+491234567890"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    func testValidFrenchPhoneNumber() throws {
        let validPhone = "+33123456789"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    func testValidJapanesePhoneNumber() throws {
        let validPhone = "+81312345678"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    func testValidIndianPhoneNumber() throws {
        let validPhone = "+919876543210"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    func testValidBrazilianPhoneNumber() throws {
        let validPhone = "+5511987654321"
        XCTAssertTrue(PhoneNumberValidator.isValid(validPhone))
        
        let result = try PhoneNumberValidator.validate(validPhone)
        XCTAssertEqual(result, validPhone)
    }
    
    // MARK: - Invalid Format
    
    func testMissingPlusSign() throws {
        let invalidPhone = "14155552671"
        XCTAssertFalse(PhoneNumberValidator.isValid(invalidPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(invalidPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .invalidFormat)
        }
    }
    
    func testInvalidCharacters() throws {
        let invalidPhone = "+1-415-555-2671"
        XCTAssertFalse(PhoneNumberValidator.isValid(invalidPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(invalidPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .invalidCharacters)
        }
    }
    
    func testSpacesInPhoneNumber() throws {
        let invalidPhone = "+1 415 555 2671"
        XCTAssertFalse(PhoneNumberValidator.isValid(invalidPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(invalidPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .invalidCharacters)
        }
    }
    
    // MARK: - Invalid Country Codes
    
    func testInvalidCountryCode() throws {
        let invalidPhone = "+99123456789"
        XCTAssertFalse(PhoneNumberValidator.isValid(invalidPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(invalidPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .invalidCountryCode)
        }
    }
    
    func testUnsupportedCountryCode() throws {
        let invalidPhone = "+358123456789" // Finland (not in supported list)
        XCTAssertFalse(PhoneNumberValidator.isValid(invalidPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(invalidPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .invalidCountryCode)
        }
    }
    
    // MARK: - Length Validation
    
    func testPhoneNumberTooShort() throws {
        let shortPhone = "+12345"
        XCTAssertFalse(PhoneNumberValidator.isValid(shortPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(shortPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .tooShort)
        }
    }
    
    func testPhoneNumberTooLong() throws {
        let longPhone = "+141555267101234567890"
        XCTAssertFalse(PhoneNumberValidator.isValid(longPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(longPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .tooLong)
        }
    }
    
    // MARK: - Empty Input
    
    func testEmptyPhoneNumber() throws {
        let emptyPhone = ""
        XCTAssertFalse(PhoneNumberValidator.isValid(emptyPhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(emptyPhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .emptyInput)
        }
    }
    
    func testWhitespaceOnlyPhone() throws {
        let whitespacePhone = "   "
        XCTAssertFalse(PhoneNumberValidator.isValid(whitespacePhone))
        
        XCTAssertThrowsError(try PhoneNumberValidator.validate(whitespacePhone)) { error in
            XCTAssertEqual(error as? PhoneValidationError, .emptyInput)
        }
    }
    
    // MARK: - Formatting
    
    func testFormatUSPhoneNumber() throws {
        let phone = "+14155552671"
        let formatted = PhoneNumberValidator.formatPhoneNumber(phone)
        XCTAssertEqual(formatted, "+1 (415) 555-2671")
    }
    
    func testFormatInternationalPhoneNumber() throws {
        let phone = "+441632960000"
        let formatted = PhoneNumberValidator.formatPhoneNumber(phone)
        // Should be formatted as +X XXX XXX XXXX
        XCTAssertTrue(formatted.hasPrefix("+44"))
    }
    
    func testValidateAndFormat() throws {
        let phone = "+14155552671"
        let result = try PhoneNumberValidator.validateAndFormat(phone)
        XCTAssertEqual(result, "+1 (415) 555-2671")
    }
    
    // MARK: - Country Suggestion
    
    func testSuggestCountryUS() throws {
        let phone = "+14155552671"
        let country = PhoneNumberValidator.suggestCountry(phone)
        XCTAssertEqual(country, "United States/Canada")
    }
    
    func testSuggestCountryUK() throws {
        let phone = "+441632960000"
        let country = PhoneNumberValidator.suggestCountry(phone)
        XCTAssertEqual(country, "United Kingdom")
    }
    
    func testSuggestCountryAustralia() throws {
        let phone = "+61212345678"
        let country = PhoneNumberValidator.suggestCountry(phone)
        XCTAssertEqual(country, "Australia")
    }
    
    func testSuggestCountryInvalid() throws {
        let phone = "+99123456789"
        let country = PhoneNumberValidator.suggestCountry(phone)
        XCTAssertNil(country)
    }
    
    // MARK: - Supported Countries
    
    func testGetSupportedCountryCodes() {
        let codes = PhoneNumberValidator.getSupportedCountryCodes()
        XCTAssertGreaterThan(codes.count, 15)
        XCTAssertTrue(codes.contains("+1"))
        XCTAssertTrue(codes.contains("+44"))
        XCTAssertTrue(codes.contains("+33"))
        XCTAssertTrue(codes.contains("+91"))
    }
    
    func testGetCountryInfo() {
        let info = PhoneNumberValidator.getCountryInfo(for: "+1")
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.0, "+1")
        XCTAssertEqual(info?.1, "United States/Canada")
    }
    
    func testGetCountryInfoInvalid() {
        let info = PhoneNumberValidator.getCountryInfo(for: "+999")
        XCTAssertNil(info)
    }
    
    // MARK: - Edge Cases
    
    func testMinimumValidLength() throws {
        let minPhone = "+12345678901" // +1 + 10 digits = 12 chars
        XCTAssertTrue(PhoneNumberValidator.isValid(minPhone))
    }
    
    func testMaximumValidLength() throws {
        let maxPhone = "+9876543210123" // +98 + 13 digits = 15 chars
        XCTAssertFalse(PhoneNumberValidator.isValid(maxPhone)) // Invalid country code
    }
    
    func testThreeDigitCountryCode() throws {
        // Saudi Arabia has +966 (3-digit code)
        let saudiPhone = "+966123456789"
        XCTAssertTrue(PhoneNumberValidator.isValid(saudiPhone))
    }
    
    func testUAECountryCode() throws {
        // UAE has +971 (3-digit code)
        let uaePhone = "+971501234567"
        XCTAssertTrue(PhoneNumberValidator.isValid(uaePhone))
    }
}

// MARK: - Circle Member Tests

class CircleMemberTests: XCTestCase {
    
    func testCircleMemberCreationWithValidPhone() throws {
        let member = try CircleMember(
            name: "John Doe",
            phoneNumber: "+14155552671",
            role: .member
        )
        
        XCTAssertEqual(member.name, "John Doe")
        XCTAssertEqual(member.phoneNumber, "+14155552671")
        XCTAssertEqual(member.role, .member)
        XCTAssertTrue(member.isActive)
        XCTAssertTrue(member.isPhoneValid)
    }
    
    func testCircleMemberCreationWithInvalidPhone() throws {
        XCTAssertThrowsError(try CircleMember(
            name: "John Doe",
            phoneNumber: "12345",
            role: .member
        ))
    }
    
    func testCircleMemberEmptyName() throws {
        XCTAssertThrowsError(try CircleMember(
            name: "",
            phoneNumber: "+14155552671",
            role: .member
        ))
    }
    
    func testCircleMemberNameTooShort() throws {
        XCTAssertThrowsError(try CircleMember(
            name: "A",
            phoneNumber: "+14155552671",
            role: .member
        ))
    }
    
    func testCircleMemberNameTooLong() throws {
        let longName = String(repeating: "A", count: 51)
        XCTAssertThrowsError(try CircleMember(
            name: longName,
            phoneNumber: "+14155552671",
            role: .member
        ))
    }
    
    func testCircleMemberCountryLookup() throws {
        let member = try CircleMember(
            name: "UK User",
            phoneNumber: "+441632960000",
            role: .member
        )
        
        XCTAssertEqual(member.countryFromPhone, "United Kingdom")
    }
    
    func testAddDeviceToken() throws {
        var member = try CircleMember(
            name: "John Doe",
            phoneNumber: "+14155552671",
            role: .member
        )
        
        member.addDeviceToken("token123")
        XCTAssertTrue(member.deviceTokens.contains("token123"))
    }
    
    func testRemoveDeviceToken() throws {
        var member = try CircleMember(
            name: "John Doe",
            phoneNumber: "+14155552671",
            role: .member
        )
        
        member.addDeviceToken("token123")
        member.removeDeviceToken("token123")
        XCTAssertFalse(member.deviceTokens.contains("token123"))
    }
}

// MARK: - Circle Tests

class CircleTests: XCTestCase {
    
    func testCircleCreation() throws {
        let circle = try Circle(
            name: "Family Circle",
            description: "Close family",
            creatorId: "user123"
        )
        
        XCTAssertEqual(circle.name, "Family Circle")
        XCTAssertEqual(circle.description, "Close family")
        XCTAssertEqual(circle.creatorId, "user123")
        XCTAssertTrue(circle.isPrivate)
        XCTAssertEqual(circle.maxMembers, 10)
        XCTAssertEqual(circle.memberCount, 0)
    }
    
    func testAddMemberToCircle() throws {
        var circle = try Circle(
            name: "Family Circle",
            creatorId: "user123"
        )
        
        try circle.addMember(
            name: "John Doe",
            phoneNumber: "+14155552671",
            role: .member
        )
        
        XCTAssertEqual(circle.memberCount, 1)
        XCTAssertFalse(circle.isFull)
        XCTAssertEqual(circle.availableSlots, 9)
    }
    
    func testAddDuplicatePhoneMember() throws {
        var circle = try Circle(
            name: "Family Circle",
            creatorId: "user123"
        )
        
        try circle.addMember(
            name: "John Doe",
            phoneNumber: "+14155552671"
        )
        
        // Should throw duplicate error
        XCTAssertThrowsError(try circle.addMember(
            name: "John Smith",
            phoneNumber: "+14155552671"
        ))
    }
    
    func testRemoveMemberFromCircle() throws {
        var circle = try Circle(
            name: "Family Circle",
            creatorId: "user123"
        )
        
        try circle.addMember(
            name: "John Doe",
            phoneNumber: "+14155552671"
        )
        
        XCTAssertEqual(circle.memberCount, 1)
        
        try circle.removeMember(byPhoneNumber: "+14155552671")
        
        XCTAssertEqual(circle.memberCount, 0)
    }
    
    func testRemoveNonexistentMember() throws {
        var circle = try Circle(
            name: "Family Circle",
            creatorId: "user123"
        )
        
        XCTAssertThrowsError(try circle.removeMember(byPhoneNumber: "+14155552671"))
    }
    
    func testFindMemberByPhone() throws {
        var circle = try Circle(
            name: "Family Circle",
            creatorId: "user123"
        )
        
        try circle.addMember(
            name: "John Doe",
            phoneNumber: "+14155552671"
        )
        
        let found = try circle.findMember(byPhoneNumber: "+14155552671")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "John Doe")
    }
    
    func testCircleCapacity() throws {
        var circle = try Circle(
            name: "Small Circle",
            creatorId: "user123",
            maxMembers: 2
        )
        
        try circle.addMember(name: "User 1", phoneNumber: "+14155552671")
        try circle.addMember(name: "User 2", phoneNumber: "+14155552672")
        
        XCTAssertTrue(circle.isFull)
        XCTAssertEqual(circle.availableSlots, 0)
        
        // Should not be able to add more
        XCTAssertThrowsError(try circle.addMember(
            name: "User 3",
            phoneNumber: "+14155552673"
        ))
    }
}
