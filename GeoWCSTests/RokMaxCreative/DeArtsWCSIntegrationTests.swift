//
//  DeArtsWCSIntegrationTests.swift
//  GeoWCSTests – RokMax (DeArtsWCS) Integration Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Integration tests for DeArtsWCS app workflows combining multiple components.
//

import XCTest
@testable import GeoWCS

final class DeArtsWCSIntegrationTests: XCTestCase {

    private var model: AppModel!

    override func setUp() {
        super.setUp()
        model = AppModel()
    }

    override func tearDown() {
        model = nil
        super.tearDown()
    }

    // MARK: - Image Generation Workflow

    func testGenerateImageWorkflow() async {
        let service = TextToImageService()
        let prompt = "A peaceful garden scene"
        
        // 1. User enters prompt and generates image
        guard let image = await service.generateImage(from: prompt) else {
            XCTFail("Image generation failed")
            return
        }
        
        // 2. Image is added to model
        model.generatedImages.insert(image, at: 0)
        model.statusMessage = "Generated an image"
        
        // 3. Verify state
        XCTAssertEqual(model.generatedImages.count, 1)
        XCTAssertEqual(model.statusMessage, "Generated an image")
    }

    func testMultipleImageGenerations() async {
        let service = TextToImageService()
        let prompts = [
            "A peaceful morning",
            "A gentle afternoon",
            "A calm evening"
        ]
        
        for prompt in prompts {
            guard let image = await service.generateImage(from: prompt) else {
                XCTFail("Failed to generate image for: \(prompt)")
                return
            }
            
            model.generatedImages.insert(image, at: 0)
        }
        
        XCTAssertEqual(model.generatedImages.count, prompts.count)
    }

    // MARK: - Photo Capture Workflow

    func testPhotoCaptureWorkflow() {
        let imageService = TextToImageService()
        let testPhoto = ImageFixture.capturedPhotoPlaceholder
        
        // 1. User captures photo (simulated)
        model.capturedPhotos.insert(testPhoto, at: 0)
        model.statusMessage = "Captured a photo"
        
        // 2. Verify state
        XCTAssertEqual(model.capturedPhotos.count, 1)
        XCTAssertEqual(model.statusMessage, "Captured a photo")
        XCTAssertEqual(model.capturedPhotos.first, testPhoto)
    }

    func testMultiplePhotoCapturesSequence() {
        let photo1 = ImageFixture.makeImageWithText("Photo 1")
        let photo2 = ImageFixture.makeImageWithText("Photo 2")
        let photo3 = ImageFixture.makeImageWithText("Photo 3")
        
        // Simulate taking multiple photos
        model.capturedPhotos.insert(photo1, at: 0)
        model.capturedPhotos.insert(photo2, at: 0)
        model.capturedPhotos.insert(photo3, at: 0)
        
        // Verify LIFO order (most recent first)
        XCTAssertEqual(model.capturedPhotos.count, 3)
        XCTAssertEqual(model.capturedPhotos[0], photo3)
        XCTAssertEqual(model.capturedPhotos[1], photo2)
        XCTAssertEqual(model.capturedPhotos[2], photo1)
    }

    // MARK: - Painting Workflow

    func testPaintingCreationAndSave() {
        let painting = ImageFixture.paintingPlaceholder
        
        // 1. User creates and saves painting
        model.savedPaintings.insert(painting, at: 0)
        model.statusMessage = "Saved a painting"
        
        // 2. Verify saved to model
        XCTAssertEqual(model.savedPaintings.count, 1)
        XCTAssertEqual(model.statusMessage, "Saved a painting")
    }

    func testMultiplePaintingsSavedProcedurallyInOrder() {
        let paintings = [
            ImageFixture.makeImageWithText("Painting 1", color: .red),
            ImageFixture.makeImageWithText("Painting 2", color: .blue),
            ImageFixture.makeImageWithText("Painting 3", color: .green)
        ]
        
        for painting in paintings {
            model.savedPaintings.insert(painting, at: 0)
        }
        
        // Most recent painting should be first
        XCTAssertEqual(model.savedPaintings[0], paintings[2])
        XCTAssertEqual(model.savedPaintings[1], paintings[1])
        XCTAssertEqual(model.savedPaintings[2], paintings[0])
    }

    // MARK: - Video Recording Workflow

    func testVideoRecordingWorkflow() {
        let videoURL = URLFixture.videoURL
        
        // 1. User records video (simulated)
        model.recordedVideoURL = videoURL
        model.statusMessage = "Saved a video memory"
        
        // 2. Verify state
        XCTAssertEqual(model.recordedVideoURL, videoURL)
        XCTAssertEqual(model.statusMessage, "Saved a video memory")
    }

    // MARK: - Tab Navigation with Content

    func testTabNavigationWorkflowForImage() async {
        // Start on home
        XCTAssertEqual(model.selectedTab, .home)
        
        // Navigate to imagine tab
        model.selectedTab = .imagine
        XCTAssertEqual(model.selectedTab, .imagine)
        
        // Generate image
        let service = TextToImageService()
        if let image = await service.generateImage(from: "Test") {
            model.generatedImages.insert(image, at: 0)
            model.statusMessage = "Generated an image"
        }
        
        // Navigate to memories to view
        model.selectedTab = .memories
        XCTAssertEqual(model.selectedTab, .memories)
        XCTAssertEqual(model.generatedImages.count, 1)
    }

    func testTabNavigationWorkflowForPhoto() {
        // Start on home
        XCTAssertEqual(model.selectedTab, .home)
        
        // Navigate to camera
        model.selectedTab = .camera
        XCTAssertEqual(model.selectedTab, .camera)
        
        // Capture photo
        let photo = ImageFixture.capturedPhotoPlaceholder
        model.capturedPhotos.insert(photo, at: 0)
        
        // Navigate to memories
        model.selectedTab = .memories
        XCTAssertEqual(model.capturedPhotos.count, 1)
    }

    func testCompleteCreativeSessionWorkflow() async {
        // 1. User starts on home - review welcome
        model.selectedTab = .home
        XCTAssertEqual(model.statusMessage, "Welcome")
        
        // 2. Generate an image
        model.selectedTab = .imagine
        let service = TextToImageService()
        if let image = await service.generateImage(from: "Morning light") {
            model.generatedImages.insert(image, at: 0)
            model.statusMessage = "Generated an image"
        }
        
        // 3. Take a photo
        model.selectedTab = .camera
        let photo = ImageFixture.capturedPhotoPlaceholder
        model.capturedPhotos.insert(photo, at: 0)
        model.statusMessage = "Captured a photo"
        
        // 4. Paint
        model.selectedTab = .paint
        let painting = ImageFixture.paintingPlaceholder
        model.savedPaintings.insert(painting, at: 0)
        model.statusMessage = "Saved a painting"
        
        // 5. View all memories
        model.selectedTab = .memories
        XCTAssertEqual(model.generatedImages.count, 1)
        XCTAssertEqual(model.capturedPhotos.count, 1)
        XCTAssertEqual(model.savedPaintings.count, 1)
    }

    // MARK: - Status Message Updates

    func testStatusMessageUpdatesReflectActivity() {
        XCTAssertEqual(model.statusMessage, "Welcome")
        
        model.statusMessage = "Generated an image"
        XCTAssertEqual(model.statusMessage, "Generated an image")
        
        model.statusMessage = "Captured a photo"
        XCTAssertEqual(model.statusMessage, "Captured a photo")
        
        model.statusMessage = "Saved a painting"
        XCTAssertEqual(model.statusMessage, "Saved a painting")
        
        model.statusMessage = "Saved a video memory"
        XCTAssertEqual(model.statusMessage, "Saved a video memory")
    }

    // MARK: - Memory Collection Full Workflow

    func testFullMemoryCollectionBuildup() async {
        let service = TextToImageService()
        
        // Generate multiple images
        for i in 1...3 {
            if let image = await service.generateImage(from: "Image \(i)") {
                model.generatedImages.insert(image, at: 0)
            }
        }
        
        // Capture multiple photos
        for i in 1...2 {
            let photo = ImageFixture.makeImageWithText("Photo \(i)")
            model.capturedPhotos.insert(photo, at: 0)
        }
        
        // Create multiple paintings
        for i in 1...3 {
            let painting = ImageFixture.makeImageWithText("Painting \(i)")
            model.savedPaintings.insert(painting, at: 0)
        }
        
        // Verify memories
        XCTAssertEqual(model.generatedImages.count, 3)
        XCTAssertEqual(model.capturedPhotos.count, 2)
        XCTAssertEqual(model.savedPaintings.count, 3)
    }

    // MARK: - Error Recovery

    func testModelCanbeResetToInitialState() {
        // Build up state
        model.generatedImages.insert(ImageFixture.generatedImagePlaceholder, at: 0)
        model.capturedPhotos.insert(ImageFixture.capturedPhotoPlaceholder, at: 0)
        model.selectedTab = .paint
        model.statusMessage = "Test state"
        
        // Reset
        model.reset()
        
        // Verify initial state
        XCTAssertEqual(model.selectedTab, .home)
        XCTAssertTrue(model.generatedImages.isEmpty)
        XCTAssertTrue(model.capturedPhotos.isEmpty)
        XCTAssertEqual(model.statusMessage, "Welcome")
    }
}
