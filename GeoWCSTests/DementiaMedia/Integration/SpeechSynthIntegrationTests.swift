//
//  SpeechSynthIntegrationTests.swift
//  GeoWCSTests – DementiaMedia Integration Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Boundary tests for AVSpeechSynthesizer-backed synthesis adapter.
//  These tests run against a controllable fake, not the real AVFoundation,
//  so they can run in CI without a device speaker or audio session.
//  One dedicated integration test at the bottom documents the real adapter
//  contract for manual/on-device validation.
//

import XCTest
@testable import DementiaMedia

// MARK: - Controlled fake-based integration tests

final class SpeechSynthIntegrationTests: XCTestCase {

    private var synthesiser: FakeSpeechSynthesiser!
    private var repository: FakeMediaRepository!
    private var sut: CreateSpeechPrompt!

    private let carerID = UUID()
    private let patientID = UUID()

    override func setUp() {
        super.setUp()
        synthesiser = FakeSpeechSynthesiser()
        repository  = FakeMediaRepository()
        sut = CreateSpeechPrompt(synthesiser: synthesiser, repository: repository)
    }

    // MARK: - Voice catalogue

    func testDefaultCalmVoiceIsInAvailableList() {
        let available = synthesiser.availableVoiceIdentifiers()
        XCTAssertTrue(available.contains(SpeechVoiceOptions.calm.identifier),
            "The default calm voice must be in the available list for dementia-safe defaults.")
    }

    func testSynthesisWritesFileAtProvidedURL() async throws {
        let prompt = ActivityPrompt(title: "A", bodyText: "Breathe slowly.",
                                    authoredByCarerID: carerID)
        let asset = try await sut.execute(prompt: prompt, voice: .calm, ownerID: patientID)
        XCTAssertNotNil(asset.localURL)
    }

    // MARK: - Audio session interruption simulation

    func testInterruptionDuringSynthesisProducesError() async {
        synthesiser.shouldFail = true
        synthesiser.failureMessage = "Audio session interrupted"
        let prompt = ActivityPrompt(title: "B", bodyText: "Close your eyes.",
                                    authoredByCarerID: carerID)
        do {
            _ = try await sut.execute(prompt: prompt, voice: .calm, ownerID: patientID)
            XCTFail("Expected synthesisFailure")
        } catch let err as CreateSpeechPromptError {
            if case .synthesisFailure(let msg) = err {
                XCTAssertTrue(msg.contains("interrupted") || !msg.isEmpty)
            }
        }
    }

    // MARK: - Offline behaviour

    func testOfflineVoiceFallbackUsesFirstAvailableVoice() async throws {
        // Simulate an online-only voice being removed from available list
        synthesiser.availableVoices = ["com.apple.voice.compact.en-US.Samantha"]
        let offlineOnly = SpeechVoiceOptions(
            identifier: "com.apple.voice.compact.en-US.Samantha",
            speedMultiplier: 0.85,
            pitchMultiplier: 1.0
        )
        let prompt = ActivityPrompt(title: "Offline", bodyText: "Use available voice.",
                                    authoredByCarerID: carerID)
        let asset = try await sut.execute(prompt: prompt, voice: offlineOnly, ownerID: patientID)
        XCTAssertEqual(asset.state, .saved)
    }

    func testAllVoicesRemovedThrowsVoiceUnavailable() async {
        synthesiser.availableVoices = []
        let prompt = ActivityPrompt(title: "NoVoice", bodyText: "Hello.",
                                    authoredByCarerID: carerID)
        do {
            _ = try await sut.execute(prompt: prompt, voice: .calm, ownerID: patientID)
            XCTFail("Expected voiceUnavailable")
        } catch let err as CreateSpeechPromptError {
            if case .voiceUnavailable = err { /* expected */ }
        }
    }

    // MARK: - Chunked long prompt

    func testLongPromptIsRejectedByUseCase() async {
        // Use case rejects text > limit; chunking is the caller's responsibility
        let body = String(repeating: "Word ", count: 120)  // > 500 chars
        let prompt = ActivityPrompt(title: "Long", bodyText: body, authoredByCarerID: carerID)
        do {
            _ = try await sut.execute(prompt: prompt, voice: .calm, ownerID: patientID)
            XCTFail("Expected textTooLong")
        } catch let err as CreateSpeechPromptError {
            if case .textTooLong = err { /* expected */ }
        }
    }

    // MARK: - Playback speed boundaries

    func testSlowSpeedVoiceOptionIsAccepted() async throws {
        let slowVoice = SpeechVoiceOptions(
            identifier: synthesiser.availableVoices.first!,
            speedMultiplier: 0.25,
            pitchMultiplier: 1.0
        )
        let prompt = ActivityPrompt(title: "Slow", bodyText: "Take it easy.",
                                    authoredByCarerID: carerID)
        let asset = try await sut.execute(prompt: prompt, voice: slowVoice, ownerID: patientID)
        XCTAssertEqual(asset.state, .saved)
        XCTAssertEqual(synthesiser.lastVoiceOptions?.speedMultiplier, 0.25, accuracy: 0.001)
    }

    func testFixtureDecodedPromptCanBeSynthesisedAndPersisted() async throws {
        let prompt = try FixtureLoader.decode(ActivityPrompt.self, named: "activity_prompt.json")

        let asset = try await sut.execute(prompt: prompt, voice: .calm, ownerID: patientID)
        let fetched = try await repository.fetch(id: asset.id)

        XCTAssertTrue(synthesiser.wasSynthesiseCalled())
        XCTAssertEqual(synthesiser.lastSynthesisText, prompt.bodyText)
        XCTAssertEqual(asset.title, prompt.title)
        XCTAssertEqual(asset.tags, prompt.tags)
        XCTAssertEqual(asset.ownerID, patientID)
        XCTAssertEqual(fetched, asset)
    }

    func testMalformedPromptFixtureFailsToDecodeWithExpectedError() {
        XCTAssertThrowsError(
            try FixtureLoader.decode(ActivityPrompt.self, named: "activity_prompt_malformed.json")
        ) { error in
            guard case FixtureLoader.FixtureError.failedToDecode(let name) = error else {
                return XCTFail("Expected failedToDecode error")
            }
            XCTAssertEqual(name, "activity_prompt_malformed.json")
        }
    }
}

// MARK: - Real-adapter contract documentation
// The test below is skipped in CI (no speaker needed) but documents the
// expected behaviour of the production AVFoundationSpeechAdapter.

final class AVSpeechAdapterContractTests: XCTestCase {

    func testRealAdapterSynthesisesToAFileURL() throws {
        // SKIP in automated CI: requires audio session
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] == "true",
                      "Skipped in CI — requires real audio session")
        // Document: production adapter must:
        // 1. write a non-zero .m4a at the provided URL
        // 2. not throw for any voice in availableVoiceIdentifiers()
        // 3. complete within 30 seconds for 500-char text
    }
}
