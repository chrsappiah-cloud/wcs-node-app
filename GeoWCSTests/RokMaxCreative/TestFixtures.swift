//
//  TestFixtures.swift
//  GeoWCSTests – RokMax (DeArtsWCS) Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Test fixtures and helper functions for DeArtsWCS test suite.
//

import UIKit
@testable import GeoWCS

// MARK: - Image Fixtures

enum ImageFixture {
    /// Generate a simple test image with specified color
    static func makeColoredImage(color: UIColor, size: CGSize = CGSize(width: 512, height: 512)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Generate a test image with text
    static func makeImageWithText(_ text: String, color: UIColor = .purple) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: color
            ]
            
            let nsText = NSString(string: text)
            nsText.draw(in: CGRect(x: 24, y: 200, width: 464, height: 100), withAttributes: attributes)
        }
    }

    /// Generate a gradient test image
    static func makeGradientImage(
        fromColor: UIColor = .purple,
        toColor: UIColor = .blue,
        size: CGSize = CGSize(width: 512, height: 512)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            guard let cgContext = UIGraphicsGetCurrentContext() else { return }
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [fromColor.cgColor, toColor.cgColor]
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1])!
            
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
    }

    /// Generate a test image with a specific system icon
    static func makeSystemIconImage(named iconName: String) -> UIImage? {
        return UIImage(systemName: iconName)
    }

    /// Standard test images for common scenarios
    static var emptyPaint: UIImage {
        makeColoredImage(color: .white)
    }

    static var purpleMemory: UIImage {
        makeColoredImage(color: .systemPurple)
    }

    static var capturedPhotoPlaceholder: UIImage {
        makeImageWithText("Photo", color: .systemBlue)
    }

    static var generatedImagePlaceholder: UIImage {
        makeImageWithText("Generated", color: .systemPurple)
    }

    static var paintingPlaceholder: UIImage {
        makeImageWithText("Painting", color: .systemRed)
    }
}

// MARK: - AppModel Fixtures

extension AppModel {
    /// Create an AppModel pre-populated with test data
    static func makeWithTestData() -> AppModel {
        let model = AppModel()
        
        // Add some test images
        model.generatedImages.insert(ImageFixture.generatedImagePlaceholder, at: 0)
        model.capturedPhotos.insert(ImageFixture.capturedPhotoPlaceholder, at: 0)
        model.savedPaintings.insert(ImageFixture.paintingPlaceholder, at: 0)
        
        // Set test status
        model.statusMessage = "Test data loaded"
        
        return model
    }

    /// Reset model to initial state
    func reset() {
        selectedTab = .home
        generatedImages = []
        savedPaintings = []
        capturedPhotos = []
        recordedVideoURL = nil
        statusMessage = "Welcome"
    }
}

// MARK: - URL Fixtures

enum URLFixture {
    /// Generate a fake video file URL
    static var videoURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video_\(UUID().uuidString)")
            .appendingPathExtension("mov")
    }

    /// Generate a fake audio file URL
    static var audioURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("test_audio_\(UUID().uuidString)")
            .appendingPathExtension("m4a")
    }

    /// Generate a fake painting file URL
    static var paintingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("painting_\(UUID().uuidString)")
            .appendingPathExtension("png")
    }
}

// MARK: - Prompt Fixtures

enum PromptFixture {
    static let simple = "A peaceful garden"
    static let complex = "A serene landscape with rolling hills, wildflowers in bloom, and a gentle stream reflecting sunset colors"
    static let emotional = "A moment of joy and connection"
    static let therapeutic = "Soft colors and gentle shapes that bring calm"
    
    static var all: [String] {
        [simple, complex, emotional, therapeutic]
    }
}

// MARK: - Test Data Generators

enum TestDataGenerator {
    /// Generate multiple test images
    static func generateImages(count: Int) -> [UIImage] {
        (0..<count).map { index in
            ImageFixture.makeImageWithText("Image \(index + 1)")
        }
    }

    /// Generate test images collection in AppModel
    static func populateAppModel(_ model: AppModel, imageCount: Int = 5) {
        let images = generateImages(count: imageCount)
        model.generatedImages = images
    }
}

// MARK: - Assertion Helpers

enum TestAssertions {
    /// Verify image dimensions
    static func assertImageDimensions(
        _ image: UIImage?,
        expectedWidth: CGFloat = 512,
        expectedHeight: CGFloat = 512,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let image = image else {
            XCTFail("Image is nil", file: file, line: line)
            return
        }
        
        XCTAssertEqual(image.size.width, expectedWidth, "Image width mismatch", file: file, line: line)
        XCTAssertEqual(image.size.height, expectedHeight, "Image height mismatch", file: file, line: line)
    }

    /// Verify image exists and is usable
    static func assertImageIsValid(_ image: UIImage?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(image, "Image should not be nil", file: file, line: line)
        if let image = image {
            XCTAssertNotNil(image.cgImage, "Image should have cgImage", file: file, line: line)
            XCTAssertGreaterThan(image.size.width, 0, "Image width should be positive", file: file, line: line)
            XCTAssertGreaterThan(image.size.height, 0, "Image height should be positive", file: file, line: line)
        }
    }
}
