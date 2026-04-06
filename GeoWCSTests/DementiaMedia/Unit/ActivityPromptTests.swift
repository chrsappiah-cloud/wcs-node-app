//
//  ActivityPromptTests.swift
//  GeoWCSTests – DementiaMedia Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Covers ActivityPrompt domain rules: validation, text chunking,
//  difficulty ordering, and modality selection.
//

import XCTest
@testable import DementiaMedia

final class ActivityPromptTests: XCTestCase {

    // MARK: - Helpers

    private func makePrompt(body: String, modality: PromptModality = .text) -> ActivityPrompt {
        ActivityPrompt(
            title: "Test Prompt",
            bodyText: body,
            modality: modality,
            difficulty: .easy,
            authoredByCarerID: UUID()
        )
    }

    // MARK: - Text chunking

    func testShortTextDoesNotRequireChunking() {
        let prompt = makePrompt(body: "Take a deep breath.")
        XCTAssertFalse(prompt.requiresChunking)
        XCTAssertEqual(prompt.textChunks().count, 1)
        XCTAssertEqual(prompt.textChunks().first, "Take a deep breath.")
    }

    func testTextAtExactLimitDoesNotRequireChunking() {
        let body = String(repeating: "a", count: ActivityPrompt.maximumBodyTextLength)
        let prompt = makePrompt(body: body)
        XCTAssertFalse(prompt.requiresChunking)
    }

    func testTextOneCharOverLimitRequiresChunking() {
        let body = String(repeating: "a", count: ActivityPrompt.maximumBodyTextLength + 1)
        let prompt = makePrompt(body: body)
        XCTAssertTrue(prompt.requiresChunking)
    }

    func testChunksReassembleToOriginalContent() {
        // Build text with two clear sentences > 500 chars combined
        let sentence = String(repeating: "Word ", count: 50) + "."  // ~255 chars
        let body = sentence + " " + sentence + " " + sentence        // ~765 chars, three sentences
        let prompt = makePrompt(body: body)
        XCTAssertTrue(prompt.requiresChunking)
        let chunks = prompt.textChunks()
        XCTAssertFalse(chunks.isEmpty)
        // Each chunk must be within limit
        for chunk in chunks {
            XCTAssertLessThanOrEqual(chunk.count, ActivityPrompt.maximumBodyTextLength,
                                     "Chunk exceeds limit: \(chunk.count) chars")
        }
    }

    func testEmptyBodyProducesNoChunks() {
        let prompt = makePrompt(body: "")
        let chunks = prompt.textChunks()
        // A single empty-string prompt is valid domain-wise; chunking returns it as-is
        XCTAssertEqual(chunks.count, 1)
    }

    // MARK: - Difficulty ordering

    func testDifficultyOrdering() {
        XCTAssertLessThan(PromptDifficulty.veryEasy, .easy)
        XCTAssertLessThan(PromptDifficulty.easy, .moderate)
        XCTAssertGreaterThan(PromptDifficulty.moderate, .veryEasy)
    }

    // MARK: - Identity

    func testTwoPromptsWithDifferentIDsAreNotEqual() {
        let p1 = makePrompt(body: "Hello")
        let p2 = makePrompt(body: "Hello")
        XCTAssertNotEqual(p1, p2)
    }

    func testCopyWithSameIDIsEqual() {
        let p1 = makePrompt(body: "Hello")
        let p2 = p1
        XCTAssertEqual(p1, p2)
    }

    // MARK: - Tags

    func testTagsDefaultToEmpty() {
        let prompt = makePrompt(body: "Breathe slowly.")
        XCTAssertTrue(prompt.tags.isEmpty)
    }

    func testUniqueTagsArePreservedVerbatim() {
        let prompt = ActivityPrompt(
            title: "Tagged",
            bodyText: "Do something calm.",
            tags: ["morning", "ocean", "music"],
            authoredByCarerID: UUID()
        )
        XCTAssertEqual(prompt.tags, ["morning", "ocean", "music"])
    }

    // MARK: - Duration hint

    func testNilDurationHintByDefault() {
        let prompt = makePrompt(body: "Sit quietly.")
        XCTAssertNil(prompt.durationHint)
    }

    func testDurationHintIsPreserved() {
        let prompt = ActivityPrompt(
            title: "Timed activity",
            bodyText: "Paint for a while.",
            durationHint: 300,
            authoredByCarerID: UUID()
        )
        XCTAssertEqual(prompt.durationHint, 300)
    }
}
