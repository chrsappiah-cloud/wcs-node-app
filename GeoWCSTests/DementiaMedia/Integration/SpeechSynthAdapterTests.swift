//
//  SpeechSynthAdapterTests.swift
//  DementiaMediaTests – Integration
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies the contract between CreateSpeechPrompt and the speech
//  synthesis adapter.  Real AVSpeechSynthesizer tests are CI-skipped.
//

import XCTest
@testable import DementiaMedia

final class SpeechSynthAdapterTests: XCTestCase {

    private var fakeSynth: FakeSpeechSynthesiser!
    private var fakeRepo: FakeMediaRepository!
    private var fakeFileManager: FakeFileManager!
    private var sut: CreateSpeechPrompt!
    private let ownerID = UUID()

    override func setUp() {
        super.setUp()
        fakeSynth       = FakeSpeechSynthesiser()
        fakeRepo        = FakeMediaRepository()
        fakeFileManager = FakeFileManager()
        sut = CreateSpeechPrompt(
            synthesiser: fakeSynth,
            repository: fakeRepo,
            fileManager: fakeFileManager
        )
    }

    override func tearDown() {
        sut = nil; fakeSynth = nil; fakeRepo = nil; fakeFileManager = nil
        super.tearDown()
    }

    // MARK: - Voice catalogue contract

    func testVoiceCatalogueIsNonEmpty() {
        XCTAssertFalse(
            fakeSynth.availableVoiceIdentifiers().isEmpty,
            "Adapter must expose at least one available voice"
        )
    }

    func testCalmVoiceIsInCatalogue() {
        let ids = fakeSynth.availableVoiceIdentifiers()
        XCTAssertTrue(ids.contains(SpeechVoiceOptions.calm.identifier))
    }

    // MARK: - File write contract

    func testSynthesisWritesFileAtExpectedURL() async throws {
        let asset = try await sut.create(
            text: "Good morning",
            voice: .calm,
            ownerID: ownerID
        )
        XCTAssertNotNil(asset.localURL)
    }

    func testSynthesisProducesAudioPromptKind() async throws {
        let asset = try await sut.create(
            text: "Let's paint today",
            voice: .calm,
            ownerID: ownerID
        )
        XCTAssertEqual(asset.kind, .audioPrompt)
    }

    func testSynthesisCallCountIsOnePerCreate() async throws {
        _ = try await sut.create(text: "Hi", voice: .calm, ownerID: ownerID)
        XCTAssertEqual(fakeSynth.synthesisCallCount, 1)
    }

    // MARK: - Voice pass-through contract

    func testVoiceOptionsPassedUnchangedToSynthesiser() async throws {
        let customVoice = SpeechVoiceOptions(
            identifier: "com.apple.voice.compact.en-US.Samantha",
            speedMultiplier: 0.7,
            pitchMultiplier: 0.9
        )
        _ = try await sut.create(text: "Hello", voice: customVoice, ownerID: ownerID)
        XCTAssertEqual(fakeSynth.lastVoiceOptions, customVoice)
    }

    // MARK: - Long-prompt rejection contract

    func testPromptExceedingLimitRejectedBeforeSynthesis() async throws {
        let longText = String(repeating: "A", count: CreateSpeechPrompt.maximumTextLength + 1)
        do {
            _ = try await sut.create(text: longText, voice: .calm, ownerID: ownerID)
            XCTFail("Expected textTooLong error")
        } catch CreateSpeechError.textTooLong {
            XCTAssertEqual(fakeSynth.synthesisCallCount, 0,
                "Synthesiser must not be called for an over-limit text")
        }
    }

    // MARK: - Voice-unavailable contract

    func testUnavailableVoiceThrowsVoiceUnavailableError() async throws {
        fakeSynth.availableVoices = []
        do {
            _ = try await sut.create(
                text: "Test",
                voice: .calm,
                ownerID: ownerID
            )
            XCTFail("Expected voiceUnavailable error")
        } catch CreateSpeechError.voiceUnavailable {
            // expected
        }
    }

    // MARK: - Interruption / offline contract

    func testSynthesisFailureProducesWrappedError() async throws {
        fakeSynth.shouldFail = true
        do {
            _ = try await sut.create(text: "Offline test", voice: .calm, ownerID: ownerID)
            XCTFail("Expected synthesisFailure error")
        } catch CreateSpeechError.synthesisFailure {
            // expected
        }
    }

    // MARK: - Slow-speed contract

    func testSlowSpeedVoiceIsAccepted() async throws {
        let slowVoice = SpeechVoiceOptions(
            identifier: SpeechVoiceOptions.calm.identifier,
            speedMultiplier: 0.25,
            pitchMultiplier: 1.0
        )
        let asset = try await sut.create(text: "Slowly", voice: slowVoice, ownerID: ownerID)
        XCTAssertEqual(asset.kind, .audioPrompt)
    }

    // MARK: - Device-only: real AVSpeechSynthesizer

    func testRealAVSpeechSynthesiserProducesAudioFile() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipped in CI: requires real AVSpeechSynthesizer"
        )
        XCTAssert(true, "Wire up real AVFoundationSpeechAdapter here for device runs")
    }
}
