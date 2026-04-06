//
//  CreateSpeechPromptTests.swift
//  GeoWCSTests – DementiaMedia Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Unit tests for the CreateSpeechPrompt use case.
//  All dependencies replaced with fakes; no AVFoundation involved.
//

import XCTest
@testable import DementiaMedia

final class CreateSpeechPromptTests: XCTestCase {

    // MARK: - System under test + fakes

    private var synthesiser: FakeSpeechSynthesiser!
    private var repository: FakeMediaRepository!
    private var fileManager: FakeFileManager!
    private var sut: CreateSpeechPrompt!

    private let ownerID = UUID()
    private let carerID = UUID()

    override func setUp() {
        super.setUp()
        synthesiser = FakeSpeechSynthesiser()
        repository  = FakeMediaRepository()
        fileManager = FakeFileManager()
        sut = CreateSpeechPrompt(synthesiser: synthesiser,
                                  repository: repository,
                                  fileManager: fileManager)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makePrompt(body: String = "Breathe in slowly.") -> ActivityPrompt {
        ActivityPrompt(
            title: "Morning calm",
            bodyText: body,
            authoredByCarerID: carerID
        )
    }

    private var calmVoice: SpeechVoiceOptions { .calm }

    // MARK: - Happy path

    func testSuccessfulSynthesisSavesOneAsset() async throws {
        let prompt = makePrompt()
        let asset = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)

        XCTAssertEqual(asset.kind, .audioPrompt)
        XCTAssertEqual(asset.state, .saved)
        XCTAssertEqual(asset.ownerID, ownerID)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testSynthesisReceivesCorrectText() async throws {
        let body = "Close your eyes and listen."
        let prompt = makePrompt(body: body)
        _ = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)

        XCTAssertEqual(synthesiser.lastSynthesisText, body)
    }

    func testSynthesisReceivesVoiceOptions() async throws {
        let voice = SpeechVoiceOptions(
            identifier: "com.apple.voice.compact.en-GB.Daniel",
            speedMultiplier: 0.8,
            pitchMultiplier: 1.0
        )
        _ = try await sut.execute(prompt: makePrompt(), voice: voice, ownerID: ownerID)
        XCTAssertEqual(synthesiser.lastVoiceOptions, voice)
    }

    func testAssetTitleMatchesPromptTitle() async throws {
        let prompt = makePrompt(body: "Evening routine.")
        let asset = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
        XCTAssertEqual(asset.title, prompt.title)
    }

    // MARK: - Validation errors

    func testEmptyTextThrowsEmptyTextError() async {
        let prompt = makePrompt(body: "")
        do {
            _ = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
            XCTFail("Expected emptyText error")
        } catch let error as CreateSpeechPromptError {
            XCTAssertEqual(error, .emptyText)
        }
    }

    func testWhitespaceOnlyTextThrowsEmptyTextError() async {
        let prompt = makePrompt(body: "   \n\t  ")
        do {
            _ = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
            XCTFail("Expected emptyText error")
        } catch let error as CreateSpeechPromptError {
            XCTAssertEqual(error, .emptyText)
        }
    }

    func testTextTooLongThrowsCorrectError() async {
        let body = String(repeating: "x", count: ActivityPrompt.maximumBodyTextLength + 1)
        let prompt = makePrompt(body: body)
        do {
            _ = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
            XCTFail("Expected textTooLong error")
        } catch let error as CreateSpeechPromptError {
            if case .textTooLong(let length, let limit) = error {
                XCTAssertEqual(length, body.count)
                XCTAssertEqual(limit, ActivityPrompt.maximumBodyTextLength)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testTextAtExactLimitSucceeds() async throws {
        let body = String(repeating: "a", count: ActivityPrompt.maximumBodyTextLength)
        let prompt = makePrompt(body: body)
        let asset = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
        XCTAssertEqual(asset.state, .saved)
    }

    func testUnavailableVoiceThrowsError() async {
        let unavailableVoice = SpeechVoiceOptions(
            identifier: "com.apple.voice.nonexistent",
            speedMultiplier: 1.0,
            pitchMultiplier: 1.0
        )
        let prompt = makePrompt()
        do {
            _ = try await sut.execute(prompt: prompt, voice: unavailableVoice, ownerID: ownerID)
            XCTFail("Expected voiceUnavailable error")
        } catch let error as CreateSpeechPromptError {
            if case .voiceUnavailable(let id) = error {
                XCTAssertEqual(id, "com.apple.voice.nonexistent")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Synthesis failure

    func testSynthesisFailureThrowsCorrectError() async {
        synthesiser.shouldFail = true
        synthesiser.failureMessage = "Device overloaded"
        let prompt = makePrompt()
        do {
            _ = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
            XCTFail("Expected synthesisFailure error")
        } catch let error as CreateSpeechPromptError {
            if case .synthesisFailure(let msg) = error {
                XCTAssertFalse(msg.isEmpty)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testSynthesisFailureDoesNotSaveToRepository() async {
        synthesiser.shouldFail = true
        let prompt = makePrompt()
        _ = try? await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
        XCTAssertEqual(repository.saveCallCount, 0)
    }

    // MARK: - Repository failure

    func testRepositoryFailureThrowsCorrectError() async {
        repository.shouldFailOnSave = true
        let prompt = makePrompt()
        do {
            _ = try await sut.execute(prompt: prompt, voice: calmVoice, ownerID: ownerID)
            XCTFail("Expected persistenceFailure error")
        } catch let error as CreateSpeechPromptError {
            if case .persistenceFailure = error { /* expected */ } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Spy assertions

    func testSynthesisCalledExactlyOnce() async throws {
        _ = try await sut.execute(prompt: makePrompt(), voice: calmVoice, ownerID: ownerID)
        XCTAssertTrue(synthesiser.wasSynthesiseCalled())
        XCTAssertEqual(synthesiser.synthesisCallCount, 1)
    }
}
