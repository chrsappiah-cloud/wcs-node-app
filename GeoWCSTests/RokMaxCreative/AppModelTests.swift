//
//  AppModelTests.swift
//  GeoWCSTests – RokMax (DeArtsWCS) Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Unit tests for AppModel state management and tab navigation logic.
//

import XCTest
@testable import GeoWCS

final class AppModelTests: XCTestCase {

    private var appModel: AppModel!

    override func setUp() {
        super.setUp()
        appModel = AppModel()
    }

    override func tearDown() {
        appModel = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testAppModelInitializesWithHomeTab() {
        XCTAssertEqual(appModel.selectedTab, .home,
            "AppModel should default to home tab on launch")
    }

    func testAppModelInitializesWithEmptyGeneratedImages() {
        XCTAssertTrue(appModel.generatedImages.isEmpty,
            "Generated images array must be empty on initial state")
    }

    func testAppModelInitializesWithEmptySavedPaintings() {
        XCTAssertTrue(appModel.savedPaintings.isEmpty,
            "Saved paintings array must be empty on initial state")
    }

    func testAppModelInitializesWithEmptyCapturedPhotos() {
        XCTAssertTrue(appModel.capturedPhotos.isEmpty,
            "Captured photos array must be empty on initial state")
    }

    func testAppModelInitializesWithNilRecordedVideoURL() {
        XCTAssertNil(appModel.recordedVideoURL,
            "Recorded video URL must be nil on initial state")
    }

    func testAppModelInitializesWithWelcomeMessage() {
        XCTAssertEqual(appModel.statusMessage, "Welcome",
            "AppModel should initialize with 'Welcome' status message")
    }

    // MARK: - Service Initialization

    func testAppModelCreatesImageGenerator() {
        XCTAssertNotNil(appModel.imageGenerator,
            "AppModel must initialize TextToImageService")
    }

    func testAppModelCreatesMediaRecorder() {
        XCTAssertNotNil(appModel.mediaRecorder,
            "AppModel must initialize MediaRecorderService")
    }

    func testAppModelCreatesPaintingStore() {
        XCTAssertNotNil(appModel.paintingStore,
            "AppModel must initialize PaintingStore")
    }

    // MARK: - Tab Navigation

    func testCanNavigateToImagineTab() {
        appModel.selectedTab = .imagine
        XCTAssertEqual(appModel.selectedTab, .imagine,
            "Should be able to navigate to imagine tab")
    }

    func testCanNavigateToCameraTab() {
        appModel.selectedTab = .camera
        XCTAssertEqual(appModel.selectedTab, .camera,
            "Should be able to navigate to camera tab")
    }

    func testCanNavigateToPaintTab() {
        appModel.selectedTab = .paint
        XCTAssertEqual(appModel.selectedTab, .paint,
            "Should be able to navigate to paint tab")
    }

    func testCanNavigateToMemoriesTab() {
        appModel.selectedTab = .memories
        XCTAssertEqual(appModel.selectedTab, .memories,
            "Should be able to navigate to memories tab")
    }

    // MARK: - Generated Images Collection

    func testCanAddGeneratedImage() {
        let testImage = UIImage(systemName: "photo")!
        appModel.generatedImages.append(testImage)
        
        XCTAssertEqual(appModel.generatedImages.count, 1,
            "Generated images count should increase after adding image")
        XCTAssertEqual(appModel.generatedImages.first, testImage,
            "Added image should be retrievable")
    }

    func testCanAddMultipleGeneratedImages() {
        let image1 = UIImage(systemName: "photo")!
        let image2 = UIImage(systemName: "video")!
        
        appModel.generatedImages.append(image1)
        appModel.generatedImages.append(image2)
        
        XCTAssertEqual(appModel.generatedImages.count, 2,
            "Should be able to add multiple generated images")
    }

    func testGeneratedImagesCanBeInsertedAtFront() {
        let image1 = UIImage(systemName: "photo")!
        let image2 = UIImage(systemName: "video")!
        
        appModel.generatedImages.append(image1)
        appModel.generatedImages.insert(image2, at: 0)
        
        XCTAssertEqual(appModel.generatedImages.first, image2,
            "Newly generated image should appear first (LIFO)")
        XCTAssertEqual(appModel.generatedImages.count, 2)
    }

    // MARK: - Captured Photos Collection

    func testCanAddCapturedPhoto() {
        let testImage = UIImage(systemName: "camera")!
        appModel.capturedPhotos.append(testImage)
        
        XCTAssertEqual(appModel.capturedPhotos.count, 1,
            "Captured photos count should increase after adding photo")
    }

    func testCapturedPhotosAppearFirstWhenInserted() {
        let photo1 = UIImage(systemName: "camera")!
        let photo2 = UIImage(systemName: "camera.fill")!
        
        appModel.capturedPhotos.append(photo1)
        appModel.capturedPhotos.insert(photo2, at: 0)
        
        XCTAssertEqual(appModel.capturedPhotos.first, photo2,
            "Most recent photo should appear first")
    }

    // MARK: - Saved Paintings Collection

    func testCanAddSavedPainting() {
        let testImage = UIImage(systemName: "pencil.and.scribble")!
        appModel.savedPaintings.append(testImage)
        
        XCTAssertEqual(appModel.savedPaintings.count, 1,
            "Saved paintings count should increase after saving painting")
    }

    func testSavedPaintingsAppearFirstWhenInserted() {
        let painting1 = UIImage(systemName: "pencil.and.scribble")!
        let painting2 = UIImage(systemName: "paintbrush")!
        
        appModel.savedPaintings.append(painting1)
        appModel.savedPaintings.insert(painting2, at: 0)
        
        XCTAssertEqual(appModel.savedPaintings.first, painting2,
            "Most recent painting should appear first")
    }

    // MARK: - Status Message Updates

    func testStatusMessageCanBeUpdated() {
        let newMessage = "Generated an image"
        appModel.statusMessage = newMessage
        
        XCTAssertEqual(appModel.statusMessage, newMessage,
            "Status message should update correctly")
    }

    func testStatusMessageUpdatesForPhotoCaptured() {
        let testImage = UIImage(systemName: "camera")!
        appModel.capturedPhotos.insert(testImage, at: 0)
        appModel.statusMessage = "Captured a photo"
        
        XCTAssertEqual(appModel.statusMessage, "Captured a photo",
            "Status message should reflect photo capture")
    }

    func testStatusMessageUpdatesForVideRecorded() {
        let testURL = URL(fileURLWithPath: "/tmp/test.mov")
        appModel.recordedVideoURL = testURL
        appModel.statusMessage = "Saved a video memory"
        
        XCTAssertEqual(appModel.statusMessage, "Saved a video memory",
            "Status message should reflect video recording")
        XCTAssertEqual(appModel.recordedVideoURL, testURL)
    }

    // MARK: - Video URL Management

    func testCanSetRecordedVideoURL() {
        let testURL = URL(fileURLWithPath: "/tmp/test_video.mov")
        appModel.recordedVideoURL = testURL
        
        XCTAssertEqual(appModel.recordedVideoURL, testURL,
            "Video URL should be set correctly")
    }

    func testCanClearRecordedVideoURL() {
        let testURL = URL(fileURLWithPath: "/tmp/test_video.mov")
        appModel.recordedVideoURL = testURL
        appModel.recordedVideoURL = nil
        
        XCTAssertNil(appModel.recordedVideoURL,
            "Video URL should be clearable")
    }

    // MARK: - Collection Limits (Future Policy)

    func testGeneratedImagesCountReflectsAdditions() {
        let count = 5
        for i in 0..<count {
            let image = UIImage(systemName: "photo")!
            appModel.generatedImages.append(image)
        }
        
        XCTAssertEqual(appModel.generatedImages.count, count,
            "Generated images count should match number of additions")
    }

    // MARK: - Published Property Observations

    func testAppModelConformsToObservableObject() {
        // Verify AppModel is an ObservableObject (compile-time check)
        // This test documents that AppModel is designed for SwiftUI binding
        XCTAssertTrue(appModel is ObservableObject,
            "AppModel must conform to ObservableObject for SwiftUI")
    }
}
