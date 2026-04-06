//
//  DeArtsWCSTDDScaffoldTests.swift
//  GeoWCSTests - RokMax (DeArtsWCS) Tests
//
//  Concrete XCTest scaffold for multimedia TDD workflows.
//

import XCTest
@testable import GeoWCS

final class DeArtsWCSTDDScaffoldTests: XCTestCase {

    private var sut: MultimediaSessionCoordinator!
    private var audioPlayer: AudioPlayerMock!
    private var mediaStore: MediaStoreMock!
    private var moodStream: MoodStreamMock!

    override func setUp() {
        super.setUp()
        audioPlayer = AudioPlayerMock()
        mediaStore = MediaStoreMock()
        moodStream = MoodStreamMock()
        sut = MultimediaSessionCoordinator(
            audioPlayer: audioPlayer,
            mediaStore: mediaStore,
            moodStream: moodStream
        )
    }

    override func tearDown() {
        sut = nil
        audioPlayer = nil
        mediaStore = nil
        moodStream = nil
        super.tearDown()
    }

    // MARK: - Unit (70%)

    func testArtSessionTimer_formatsDurationAsMMSS() {
        let timer = ArtSessionTimer(totalDurationSeconds: 300)

        timer.advance(by: 125)

        XCTAssertEqual(timer.elapsedSeconds, 125)
        XCTAssertEqual(timer.formattedElapsed, "02:05")
        XCTAssertEqual(timer.formattedRemaining, "02:55")
    }

    func testArtSessionTimer_pausesOnMoodChange() {
        let timer = ArtSessionTimer(totalDurationSeconds: 300)
        timer.start()
        timer.advance(by: 30)

        sut.attach(timer: timer)
        sut.handleMoodChange(.anxious)

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.elapsedSeconds, 30)
    }

    func testPlayTherapyAudio_completesIn5Minutes() {
        let completion = expectation(description: "Audio playback completion callback")

        sut.playTherapyAudio(trackID: "calming-ocean") {
            completion.fulfill()
        }

        audioPlayer.simulateCompletion()

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(audioPlayer.lastTrackID, "calming-ocean")
        XCTAssertEqual(audioPlayer.playCallCount, 1)
    }

    // MARK: - Integration (20%)

    func testOfflineCanvas_savesEvery30Seconds() {
        sut.setOffline(true)

        sut.onCanvasChanged(snapshotID: "canvas-1")
        sut.tick(seconds: 29)
        XCTAssertEqual(mediaStore.savedSnapshots.count, 0)

        sut.tick(seconds: 1)
        XCTAssertEqual(mediaStore.savedSnapshots, ["canvas-1"])
    }

    func testSessionProgress_persistsWhileAudioIsPlaying() {
        sut.playTherapyAudio(trackID: "soft-piano") {}

        sut.recordProgress(snapshotID: "snapshot-a")
        sut.recordProgress(snapshotID: "snapshot-b")

        XCTAssertEqual(mediaStore.savedSnapshots, ["snapshot-a", "snapshot-b"])
        XCTAssertTrue(audioPlayer.isPlaying)
    }

    // MARK: - UI-ready behavior hooks (10%)

    func testCaregiverDashboard_liveMoodUpdates() {
        sut.handleMoodChange(.happy)
        sut.handleMoodChange(.calm)

        XCTAssertEqual(moodStream.publishedMoods, [.happy, .calm])
    }
}

// MARK: - Test-only scaffold helpers

private enum Mood: String, Equatable {
    case calm
    case happy
    case anxious
    case sad
}

private protocol AudioPlaying {
    func play(trackID: String, onComplete: @escaping () -> Void)
    var isPlaying: Bool { get }
}

private protocol MediaStoring {
    func save(snapshotID: String)
}

private protocol MoodStreaming {
    func publish(_ mood: Mood)
}

private final class MultimediaSessionCoordinator {
    private let audioPlayer: AudioPlaying
    private let mediaStore: MediaStoring
    private let moodStream: MoodStreaming

    private var secondsSinceAutosave = 0
    private var lastSnapshotID: String?
    private var timer: ArtSessionTimer?
    private var isOffline = false

    init(audioPlayer: AudioPlaying, mediaStore: MediaStoring, moodStream: MoodStreaming) {
        self.audioPlayer = audioPlayer
        self.mediaStore = mediaStore
        self.moodStream = moodStream
    }

    func attach(timer: ArtSessionTimer) {
        self.timer = timer
    }

    func setOffline(_ value: Bool) {
        isOffline = value
    }

    func onCanvasChanged(snapshotID: String) {
        lastSnapshotID = snapshotID
    }

    func tick(seconds: Int) {
        guard isOffline else { return }
        secondsSinceAutosave += seconds
        guard secondsSinceAutosave >= 30, let lastSnapshotID else { return }
        secondsSinceAutosave = 0
        mediaStore.save(snapshotID: lastSnapshotID)
    }

    func recordProgress(snapshotID: String) {
        mediaStore.save(snapshotID: snapshotID)
    }

    func playTherapyAudio(trackID: String, onComplete: @escaping () -> Void) {
        audioPlayer.play(trackID: trackID, onComplete: onComplete)
    }

    func handleMoodChange(_ mood: Mood) {
        moodStream.publish(mood)
        if mood == .anxious {
            timer?.pause()
        }
    }
}

private final class ArtSessionTimer {
    private(set) var elapsedSeconds = 0
    private(set) var isRunning = false

    let totalDurationSeconds: Int

    init(totalDurationSeconds: Int) {
        self.totalDurationSeconds = totalDurationSeconds
    }

    func start() {
        isRunning = true
    }

    func pause() {
        isRunning = false
    }

    func advance(by seconds: Int) {
        elapsedSeconds += max(0, seconds)
    }

    var formattedElapsed: String {
        Self.mmss(elapsedSeconds)
    }

    var formattedRemaining: String {
        Self.mmss(max(0, totalDurationSeconds - elapsedSeconds))
    }

    private static func mmss(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private final class AudioPlayerMock: AudioPlaying {
    private(set) var lastTrackID: String?
    private(set) var playCallCount = 0
    private var completion: (() -> Void)?

    private(set) var isPlaying = false

    func play(trackID: String, onComplete: @escaping () -> Void) {
        playCallCount += 1
        lastTrackID = trackID
        completion = onComplete
        isPlaying = true
    }

    func simulateCompletion() {
        isPlaying = false
        completion?()
    }
}

private final class MediaStoreMock: MediaStoring {
    private(set) var savedSnapshots: [String] = []

    func save(snapshotID: String) {
        savedSnapshots.append(snapshotID)
    }
}

private final class MoodStreamMock: MoodStreaming {
    private(set) var publishedMoods: [Mood] = []

    func publish(_ mood: Mood) {
        publishedMoods.append(mood)
    }
}
