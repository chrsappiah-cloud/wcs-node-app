# DeArtsWCS (RokMax) Test Suite Documentation

## Overview

A comprehensive XCTest suite for the DeArtsWCS creative media iOS application, featuring unit tests, integration tests, and test fixtures organized into the `GeoWCSTests/RokMaxCreative/` directory.

## Test Files

### Core Test Files

#### 1. AppModelTests.swift (40+ tests)
Tests the central `AppModel` object that manages app state and services.

**Key Test Areas:**
- **Initial State** - Verifies default values on launch
- **Service Initialization** - Confirms services are created
- **Tab Navigation** - Tests switching between 5 tabs
- **Image Collections** - Generated images, captured photos, saved paintings
- **Video Management** - Recording URL handling
- **Status Messages** - State change notifications
- **Observable Compliance** - SwiftUI binding support

**Example Test:**
```swift
func testAppModelInitializesWithHomeTab() {
    XCTAssertEqual(appModel.selectedTab, .home,
        "AppModel should default to home tab on launch")
}
```

---

#### 2. TextToImageServiceTests.swift (30+ tests)
Tests the `TextToImageService` actor for AI/ML image generation.

**Key Test Areas:**
- **Generation** - Image creation from text prompts
- **Output Validation** - Dimension checking (512x512)
- **Prompt Handling** - Short, long, empty, special chars
- **Multiple Generations** - Sequential and concurrent
- **Series Generation** - Idempotence verification
- **Thread Safety** - Actor concurrency model
- **Integration** - AppModel state updates

**Example Test:**
```swift
func testGenerateImageReturnsCorrectDimensions() async {
    guard let image = await service.generateImage(from: "Test") else {
        XCTFail("Failed to generate image")
        return
    }
    XCTAssertEqual(image.size.width, 512)
    XCTAssertEqual(image.size.height, 512)
}
```

---

#### 3. CameraViewModelTests.swift (25+ tests)
Tests photo and video capture functionality.

**Key Test Areas:**
- **Session Initialization** - AVCaptureSession setup
- **Session Configuration** - Output configuration
- **Capture State** - Photo/video recording lifecycle
- **Permission Handling** - Camera/microphone access
- **Output Management** - URL and image handling
- **Thread Safety** - Concurrent configuration
- **Service Lifecycle** - Reusability verification

**Example Test:**
```swift
func testSessionConfigurationSetsHighPreset() {
    viewModel.configureSession()
    XCTAssertEqual(viewModel.session.sessionPreset, .high,
        "Session should be configured with high quality preset")
}
```

---

#### 4. CreativeTabTests.swift (20+ tests)
Tests the `CreativeTab` enumeration for navigation.

**Key Test Areas:**
- **Tab Existence** - All 5 tabs defined
- **Raw Values** - String representation
- **Identifiable** - SwiftUI identification
- **Uniqueness** - ID collision prevention
- **Order** - Consistent ordering
- **Purpose** - Documentation of each tab

**Example Test:**
```swift
func testAllTabsAreDefined() {
    XCTAssertEqual(CreativeTab.allCases.count, 5,
        "CreativeTab should define exactly 5 tabs")
}
```

---

#### 5. MediaRecorderServiceTests.swift
Placeholder tests documenting expected audio recording API.

**Future Implementation Areas:**
- Recording lifecycle (start/pause/resume/stop)
- Audio format support (M4A, MP3, WAV)
- Permission handling
- File management and cleanup
- Duration limits
- Background recording
- Error handling for interruptions

---

#### 6. PaintingStoreTests.swift
Placeholder tests documenting expected painting persistence API.

**Future Implementation Areas:**
- Painting save/load/delete
- Format support (PNG, JPEG, HEIF)
- Metadata tracking (timestamp, size, notes)
- Storage organization
- Thumbnail generation
- CloudKit sync
- Search and filtering

---

#### 7. DeArtsWCSIntegrationTests.swift (15+ tests)
Integration tests for complete workflows combining multiple components.

**Workflow Tests:**
- **Image Generation Workflow** - End-to-end generation and storage
- **Photo Capture** - Sequential photo captures with LIFO ordering
- **Painting Creation** - Create and save paintings
- **Video Recording** - Record and URL management
- **Tab Navigation** - Navigate with content state
- **Complete Session** - Full app workflow (Home → Imagine → Camera → Paint → Memories)
- **Memory Buildup** - Multiple items across all types
- **State Reset** - Recovery to initial state

**Example Test:**
```swift
func testCompleteCreativeSessionWorkflow() async {
    // 1. Start on home
    model.selectedTab = .home
    
    // 2. Generate image
    model.selectedTab = .imagine
    // ... generate and store image
    
    // 3. Take photo
    model.selectedTab = .camera
    // ... capture and store photo
    
    // 4. Paint
    model.selectedTab = .paint
    // ... create and store painting
    
    // 5. Verify memories
    model.selectedTab = .memories
    XCTAssertEqual(model.generatedImages.count, 1)
    XCTAssertEqual(model.capturedPhotos.count, 1)
    XCTAssertEqual(model.savedPaintings.count, 1)
}
```

---

### Test Utilities

#### TestFixtures.swift
Reusable test data, fixtures, and helpers.

**ImageFixture Enum:**
- `makeColoredImage()` - Solid color test images
- `makeImageWithText()` - Text overlay images
- `makeGradientImage()` - Gradient test images
- `makeSystemIconImage()` - System symbol images
- Pre-made fixtures: emptyPaint, purpleMemory, capturedPhotoPlaceholder, etc.

**AppModel Fixtures:**
- `AppModel.makeWithTestData()` - Pre-populated model
- `model.reset()` - Return to initial state

**URL Fixtures:**
- `URLFixture.videoURL` - Temp video paths
- `URLFixture.audioURL` - Temp audio paths
- `URLFixture.paintingURL` - Temp painting paths

**Prompt Fixtures:**
- Simple, complex, emotional, therapeutic prompts
- `PromptFixture.all` - All prompts array

**Test Data Generators:**
- `TestDataGenerator.generateImages(count:)` - Multiple test images
- `TestDataGenerator.populateAppModel()` - Fill model with data

**Assertion Helpers:**
- `TestAssertions.assertImageDimensions()` - Verify image size
- `TestAssertions.assertImageIsValid()` - Validate image usability

---

## Running Tests

### Unit Tests Only
```bash
bash scripts/run-tests.sh unit
```

### Integration Tests
```bash
bash scripts/run-tests.sh integration
```

### UI Tests
```bash
bash scripts/run-tests.sh ui
```

### All Tests
```bash
bash scripts/run-tests.sh all
```

### With Coverage Report
```bash
bash scripts/run-tests.sh coverage
```

### Direct Xcode Command
```bash
xcodebuild test \
  -project /Applications/GeoWCS/GeoWCS.xcodeproj \
  -scheme GeoWCS \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -only-testing:GeoWCSTests/AppModelTests
```

---

## Test Coverage Summary

| Component | Test Count | Coverage |
|-----------|-----------|----------|
| AppModel | 40+ | High |
| TextToImageService | 30+ | High |
| CameraViewModel | 25+ | High |
| CreativeTab | 20+ | High |
| Integration Workflows | 15+ | Medium |
| **Total** | **130+** | **Comprehensive** |

---

## Key Testing Patterns

### 1. Setup/Teardown
```swift
override func setUp() {
    super.setUp()
    service = TextToImageService()
}

override func tearDown() {
    service = nil
    super.tearDown()
}
```

### 2. Async Testing
```swift
func testAsyncImageGeneration() async {
    let image = await service.generateImage(from: prompt)
    XCTAssertNotNil(image)
}
```

### 3. Actor Thread Safety
```swift
func testThreadSafety() async {
    await withTaskGroup(...) { group in
        for prompt in prompts {
            group.addTask {
                await self.service.generateImage(from: prompt)
            }
        }
    }
}
```

### 4. State Management
```swift
func testStateTransition() {
    // Arrange
    let initialState = model.selectedTab
    
    // Act
    model.selectedTab = .imagine
    
    // Assert
    XCTAssertEqual(model.selectedTab, .imagine)
    XCTAssertNotEqual(model.selectedTab, initialState)
}
```

---

## Future Enhancements

1. **UI Tests** - XCUITest for view interactions
2. **Performance Tests** - Measure image generation speed
3. **Snapshot Tests** - UI rendering verification
4. **Memory Tests** - Leak detection
5. **Accessibility Tests** - A11y compliance
6. **CI/CD Integration** - GitHub Actions/Azure Pipelines
7. **Code Coverage Reporting** - Coverage.app integration

---

## Assertions Used

All tests follow XCTest standard assertions:
- `XCTAssertEqual()` - Equality checking
- `XCTAssertNotNil()` - Nil validation
- `XCTAssertTrue()/XCTAssertFalse()` - Boolean assertions
- `XCTAssertGreaterThan()` - Comparison operations
- `XCTFail()` - Manual failure with message

---

## Common Test Scenarios

### Testing Image Generation
```swift
// Verify image is created and has correct properties
guard let image = await service.generateImage(from: prompt) else {
    XCTFail("Image generation failed")
    return
}
TestAssertions.assertImageIsValid(image)
TestAssertions.assertImageDimensions(image, expectedWidth: 512, expectedHeight: 512)
```

### Testing Tab Navigation
```swift
// Verify tab transitions
XCTAssertEqual(model.selectedTab, .home)
model.selectedTab = .imagine
XCTAssertEqual(model.selectedTab, .imagine)
```

### Testing State Persistence
```swift
// Verify state survives operations
model.generatedImages.insert(image, at: 0)
XCTAssertEqual(model.generatedImages.count, 1)
XCTAssertEqual(model.generatedImages.first, image)
```

---

## Troubleshooting

### "No such module 'XCTest'" in VS Code
This is expected and not a real error - XCTest only available during Xcode builds.

### Tests timeout
Increase timeout in test settings or run with `-timeout` flag:
```bash
xcodebuild test -timeout 300 ...
```

### Simulator not available
Ensure simulator is booted:
```bash
xcrun simctl boot "iPhone 17 Pro Max"
```

### Permission errors in tests
Tests automatically handle permission stubs; no real permissions needed.

---

## Contributing New Tests

When adding new features:

1. Add corresponding test file in `GeoWCSTests/RokMaxCreative/`
2. Follow existing naming convention: `[ComponentName]Tests.swift`
3. Use MARK sections for test organization
4. Include setup/teardown methods
5. Document test purpose with clear assertion messages
6. Add fixtures to `TestFixtures.swift` if needed
7. Update this documentation

---

## References

- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Best Practices](https://developer.apple.com/videos/play/wwdc2022/110343/)
- Project TESTING.md for GeoWCS test strategy
