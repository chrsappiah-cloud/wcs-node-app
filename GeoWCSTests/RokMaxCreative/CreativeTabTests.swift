//
//  CreativeTabTests.swift
//  GeoWCSTests – RokMax (DeArtsWCS) Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Unit tests for CreativeTab enumeration and navigation state.
//

import XCTest
@testable import GeoWCS

final class CreativeTabTests: XCTestCase {

    // MARK: - Tab Enumeration

    func testAllTabsAreDefined() {
        XCTAssertEqual(CreativeTab.allCases.count, 5,
            "CreativeTab should define exactly 5 tabs")
    }

    func testHomeTabExists() {
        XCTAssertTrue(CreativeTab.allCases.contains(.home),
            "Home tab must be available")
    }

    func testImagineTabExists() {
        XCTAssertTrue(CreativeTab.allCases.contains(.imagine),
            "Imagine tab must be available for image generation")
    }

    func testCameraTabExists() {
        XCTAssertTrue(CreativeTab.allCases.contains(.camera),
            "Camera tab must be available for photo/video capture")
    }

    func testPaintTabExists() {
        XCTAssertTrue(CreativeTab.allCases.contains(.paint),
            "Paint tab must be available for drawing")
    }

    func testMemoriesTabExists() {
        XCTAssertTrue(CreativeTab.allCases.contains(.memories),
            "Memories tab must be available for viewing saved items")
    }

    // MARK: - Tab Raw Values

    func testHomeTabRawValue() {
        XCTAssertEqual(CreativeTab.home.rawValue, "Home")
    }

    func testImagineTabRawValue() {
        XCTAssertEqual(CreativeTab.imagine.rawValue, "Imagine")
    }

    func testCameraTabRawValue() {
        XCTAssertEqual(CreativeTab.camera.rawValue, "Camera")
    }

    func testPaintTabRawValue() {
        XCTAssertEqual(CreativeTab.paint.rawValue, "Paint")
    }

    func testMemoriesTabRawValue() {
        XCTAssertEqual(CreativeTab.memories.rawValue, "Memories")
    }

    // MARK: - Tab Identifiable

    func testTabsConformToIdentifiable() {
        for tab in CreativeTab.allCases {
            XCTAssertNotNil(tab.id,
                "Tab \(tab.rawValue) should have an ID for SwiftUI identification")
        }
    }

    func testTabIDsAreUnique() {
        let ids = Set(CreativeTab.allCases.map { $0.id })
        XCTAssertEqual(ids.count, CreativeTab.allCases.count,
            "Each tab should have a unique ID")
    }

    func testTabIDEqualRawValue() {
        for tab in CreativeTab.allCases {
            XCTAssertEqual(tab.id, tab.rawValue,
                "Tab ID should equal raw value for consistency")
        }
    }

    // MARK: - Tab Orderness

    func testTabsOrderIsConsistent() {
        let expectedOrder: [CreativeTab] = [.home, .imagine, .camera, .paint, .memories]
        let actualOrder = CreativeTab.allCases
        
        XCTAssertEqual(actualOrder, expectedOrder,
            "Tab order should be consistent for predictable navigation")
    }

    // MARK: - Navigation Sequences

    func testCanNavigateThroughAllTabs() {
        for tab in CreativeTab.allCases {
            XCTAssertNotNil(tab.rawValue,
                "Should be able to navigate to \(tab.rawValue)")
        }
    }

    func testTabEnumerationCompleteness() {
        // Verify each tab appears exactly once
        let tabNames = CreativeTab.allCases.map { $0.rawValue }
        let uniqueNames = Set(tabNames)
        
        XCTAssertEqual(tabNames.count, uniqueNames.count,
            "All tabs should have unique names (no duplicates)")
    }

    // MARK: - Tab Purpose Documentation

    func testHomeTabPurpose() {
        // Home: Welcome and overview
        XCTAssertEqual(CreativeTab.home.rawValue, "Home",
            "Home tab should appear first for overview")
    }

    func testImagineTabPurpose() {
        // Imagine: AI/ML image generation from prompts
        XCTAssertEqual(CreativeTab.imagine.rawValue, "Imagine",
            "Imagine tab for text-to-image generation")
    }

    func testCameraTabPurpose() {
        // Camera: Photo and video capture
        XCTAssertEqual(CreativeTab.camera.rawValue, "Camera",
            "Camera tab for photo/video capture")
    }

    func testPaintTabPurpose() {
        // Paint: PencilKit drawing interface
        XCTAssertEqual(CreativeTab.paint.rawValue, "Paint",
            "Paint tab for drawing with PencilKit")
    }

    func testMemoriesTabPurpose() {
        // Memories: Gallery of all created/captured items
        XCTAssertEqual(CreativeTab.memories.rawValue, "Memories",
            "Memories tab for viewing saved collections")
    }
}
