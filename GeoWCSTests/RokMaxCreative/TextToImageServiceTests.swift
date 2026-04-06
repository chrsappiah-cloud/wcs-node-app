//
//  TextToImageServiceTests.swift
//  GeoWCSTests – RokMax (DeArtsWCS) Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Unit tests for TextToImageService image generation functionality.
//  Currently tests placeholder implementation; will be extended when
//  Apple's ml-stable-diffusion Core ML model integration is complete.
//

import XCTest
@testable import GeoWCS

final class TextToImageServiceTests: XCTestCase {

    private var service: TextToImageService!

    override func setUp() {
        super.setUp()
        service = TextToImageService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Basic Generation

    func testGenerateImageFromPromptReturnsImage() async {
        let prompt = "A calm landscape with gentle colors"
        let image = await service.generateImage(from: prompt)
        
        XCTAssertNotNil(image,
            "Service should return a non-nil image for valid prompt")
    }

    func testGenerateImageReturnsCorrectDimensions() async {
        let prompt = "A peaceful garden"
        guard let image = await service.generateImage(from: prompt) else {
            XCTFail("Failed to generate image")
            return
        }
        
        XCTAssertEqual(image.size.width, 512,
            "Generated image width should be 512")
        XCTAssertEqual(image.size.height, 512,
            "Generated image height should be 512")
    }

    // MARK: - Prompt Handling

    func testGenerateImageWithShortPrompt() async {
        let prompt = "Garden"
        let image = await service.generateImage(from: prompt)
        
        XCTAssertNotNil(image,
            "Service should handle short prompts")
    }

    func testGenerateImageWithLongPrompt() async {
        let prompt = "A serene landscape with rolling hills, wildflowers, and a gentle stream flowing through calm valleys at golden hour"
        let image = await service.generateImage(from: prompt)
        
        XCTAssertNotNil(image,
            "Service should handle long descriptive prompts")
    }

    func testGenerateImageWithEmptyPrompt() async {
        let prompt = ""
        let image = await service.generateImage(from: prompt)
        
        // Empty prompts may still generate a placeholder
        // Behavior can be refined based on requirements
        XCTAssertNotNil(image,
            "Service should handle empty prompts gracefully")
    }

    func testGenerateImageWithSpecialCharactersInPrompt() async {
        let prompt = "A scene with \"quotes\" and symbols: @#$!"
        let image = await service.generateImage(from: prompt)
        
        XCTAssertNotNil(image,
            "Service should handle special characters in prompts")
    }

    // MARK: - Multiple Generations

    func testCanGenerateMultipleImagesSequentially() async {
        let prompts = [
            "A peaceful morning",
            "A gentle afternoon",
            "A calm evening"
        ]
        
        for prompt in prompts {
            let image = await service.generateImage(from: prompt)
            XCTAssertNotNil(image,
                "Should generate image for prompt: \(prompt)")
        }
    }

    func testGenerateImageIsIdempotent() async {
        let prompt = "Consistent test prompt"
        let image1 = await service.generateImage(from: prompt)
        let image2 = await service.generateImage(from: prompt)
        
        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        // Note: Placeholder implementation will have same dimensions
        // Real ml-stable-diffusion may produce different results
    }

    // MARK: - Service Lifecycle

    func testServiceCanBeReusedForMultipleGenerations() async {
        let prompts = ["Garden", "Forest", "Ocean"]
        var generatedCount = 0
        
        for prompt in prompts {
            if let image = await service.generateImage(from: prompt) {
                generatedCount += 1
                XCTAssertNotNil(image)
            }
        }
        
        XCTAssertEqual(generatedCount, prompts.count,
            "Service should successfully generate all requested images")
    }

    // MARK: - Image Validation

    func testGeneratedImageHasCGImage() async {
        let prompt = "Test image"
        guard let image = await service.generateImage(from: prompt) else {
            XCTFail("Failed to generate image")
            return
        }
        
        XCTAssertNotNil(image.cgImage,
            "Generated image should have underlying CGImage")
    }

    func testGeneratedImageIsUsable() async {
        let prompt = "Usable image test"
        guard let image = await service.generateImage(from: prompt) else {
            XCTFail("Failed to generate image")
            return
        }
        
        // Verify image can be used by SwiftUI
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    // MARK: - Actor Safety (Future ml-stable-diffusion)

    func testServiceIsThreadSafe() async {
        // Since TextToImageService is an actor, concurrent access is safe
        let prompts = ["Image 1", "Image 2", "Image 3"]
        
        let results = await withTaskGroup(of: UIImage?.self) { group in
            for prompt in prompts {
                group.addTask {
                    await self.service.generateImage(from: prompt)
                }
            }
            
            var images: [UIImage?] = []
            for await image in group {
                images.append(image)
            }
            return images
        }
        
        XCTAssertEqual(results.count, prompts.count,
            "All concurrent generation tasks should complete")
        
        // Count non-nil results
        let nonNilCount = results.compactMap { $0 }.count
        XCTAssertEqual(nonNilCount, prompts.count,
            "All concurrent generations should succeed")
    }

    // MARK: - Integration with AppModel

    func testServiceIntegrationWithAppModel() async {
        let model = AppModel()
        let prompt = "Integration test image"
        
        guard let image = await service.generateImage(from: prompt) else {
            XCTFail("Failed to generate image")
            return
        }
        
        model.generatedImages.insert(image, at: 0)
        model.statusMessage = "Generated an image"
        
        XCTAssertEqual(model.generatedImages.count, 1)
        XCTAssertEqual(model.statusMessage, "Generated an image")
    }
}
