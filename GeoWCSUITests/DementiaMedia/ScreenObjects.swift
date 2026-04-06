//
//  ScreenObjects.swift
//  GeoWCSUITests – DementiaMedia Screen Objects
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Page-Object / Screen-Object pattern for XCUITest.
//  Each struct wraps one logical screen and expresses user gestures as methods.
//  Tests call these objects instead of querying elements directly, so
//  accessibility identifier changes require updates in one place only.
//

import XCTest

// MARK: - HomeScreen

/// The app's top-level activity chooser screen.
struct HomeScreen {
    let app: XCUIApplication

    var paintButton:    XCUIElement { app.buttons["home_paint_button"] }
    var recordButton:   XCUIElement { app.buttons["home_record_button"] }
    var promptButton:   XCUIElement { app.buttons["home_prompts_button"] }
    var libraryButton:  XCUIElement { app.buttons["home_library_button"] }
    var slideshowButton: XCUIElement { app.buttons["home_slideshow_button"] }

    /// Waits for the home screen to appear.
    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        paintButton.waitForExistence(timeout: timeout)
    }

    func tapPaint()     { paintButton.tap() }
    func tapRecord()    { recordButton.tap() }
    func tapPrompts()   { promptButton.tap() }
    func tapLibrary()   { libraryButton.tap() }
    func tapSlideshow() { slideshowButton.tap() }
}

// MARK: - PaintScreen

/// Painting canvas screen backed by PencilKit.
struct PaintScreen {
    let app: XCUIApplication

    var canvas:         XCUIElement { app.otherElements["paint_canvas"] }
    var saveButton:     XCUIElement { app.buttons["paint_save_button"] }
    var undoButton:     XCUIElement { app.buttons["paint_undo_button"] }
    var clearButton:    XCUIElement { app.buttons["paint_clear_button"] }
    var brushSizePicker: XCUIElement { app.sliders["paint_brush_size_slider"] }
    var titleField:     XCUIElement { app.textFields["paint_title_field"] }
    var backButton:     XCUIElement { app.buttons["paint_back_button"] }

    /// Waits for the canvas to appear.
    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        canvas.waitForExistence(timeout: timeout)
    }

    /// Simulates a single diagonal stroke across the canvas.
    func drawStroke() {
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2))
        let end   = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    func tapUndo()     { undoButton.tap() }
    func tapClear()    { clearButton.tap() }
    func tapSave()     { saveButton.tap() }
    func tapBack()     { backButton.tap() }

    func setTitle(_ title: String) {
        titleField.tap()
        titleField.typeText(title)
    }

    /// Waits for the save-confirmation banner or alert to appear.
    func waitForSaveConfirmation(timeout: TimeInterval = 5) -> Bool {
        app.staticTexts["Saved"].waitForExistence(timeout: timeout)
            || app.alerts.firstMatch.waitForExistence(timeout: timeout)
    }
}

// MARK: - RecorderScreen

/// Audio-recording screen.
struct RecorderScreen {
    let app: XCUIApplication

    var recordButton:  XCUIElement { app.buttons["recorder_record_button"] }
    var stopButton:    XCUIElement { app.buttons["recorder_stop_button"] }
    var playButton:    XCUIElement { app.buttons["recorder_play_button"] }
    var waveformView:  XCUIElement { app.otherElements["recorder_waveform"] }
    var timerLabel:    XCUIElement { app.staticTexts["recorder_timer_label"] }
    var titleField:    XCUIElement { app.textFields["recorder_title_field"] }
    var saveButton:    XCUIElement { app.buttons["recorder_save_button"] }
    var backButton:    XCUIElement { app.buttons["recorder_back_button"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        recordButton.waitForExistence(timeout: timeout)
    }

    func tapRecord()  { recordButton.tap() }
    func tapStop()    { stopButton.tap() }
    func tapPlay()    { playButton.tap() }
    func tapSave()    { saveButton.tap() }

    /// Waits for the waveform to appear, indicating live capture started.
    func waitForWaveform(timeout: TimeInterval = 5) -> Bool {
        waveformView.waitForExistence(timeout: timeout)
    }

    /// Waits for the timer label to display a non-zero value.
    func waitForTimerToAdvance(timeout: TimeInterval = 5) -> Bool {
        timerLabel.waitForExistence(timeout: timeout)
    }
}

// MARK: - ActivityLibraryScreen

/// The media library that shows the patient's saved assets.
struct ActivityLibraryScreen {
    let app: XCUIApplication

    var assetGrid:     XCUIElement { app.collectionViews["library_grid"] }
    var emptyStateView: XCUIElement { app.staticTexts["library_empty_label"] }
    var backButton:    XCUIElement { app.buttons["library_back_button"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        assetGrid.waitForExistence(timeout: timeout)
            || emptyStateView.waitForExistence(timeout: timeout)
    }

    /// Returns the number of visible library cells.
    func assetCount() -> Int {
        assetGrid.cells.count
    }

    /// Taps the cell at the given index.
    func tapAsset(at index: Int) {
        assetGrid.cells.element(boundBy: index).tap()
    }

    /// Waits for a specific asset title to appear in the grid.
    func waitForAsset(titled title: String, timeout: TimeInterval = 5) -> Bool {
        app.staticTexts[title].waitForExistence(timeout: timeout)
    }
}

// MARK: - PromptCreationScreen

/// Carer-facing text-to-audio prompt creation screen.
struct PromptCreationScreen {
    let app: XCUIApplication

    var textEditor:    XCUIElement { app.textViews["prompt_text_editor"] }
    var voicePicker:   XCUIElement { app.pickers["prompt_voice_picker"] }
    var previewButton: XCUIElement { app.buttons["prompt_preview_button"] }
    var saveButton:    XCUIElement { app.buttons["prompt_save_button"] }
    var backButton:    XCUIElement { app.buttons["prompt_back_button"] }
    var charCountLabel: XCUIElement { app.staticTexts["prompt_char_count_label"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        textEditor.waitForExistence(timeout: timeout)
    }

    func enterText(_ text: String) {
        textEditor.tap()
        textEditor.typeText(text)
    }

    func tapPreview()  { previewButton.tap() }
    func tapSave()     { saveButton.tap() }

    func waitForPreviewToStart(timeout: TimeInterval = 5) -> Bool {
        app.buttons["prompt_stop_preview_button"].waitForExistence(timeout: timeout)
    }

    func waitForSaveConfirmation(timeout: TimeInterval = 5) -> Bool {
        app.staticTexts["Saved"].waitForExistence(timeout: timeout)
    }
}

// MARK: - SlideshowScreen

/// Screen that shows a video slideshow in playback mode.
struct SlideshowScreen {
    let app: XCUIApplication

    var videoPlayer:   XCUIElement { app.otherElements["slideshow_player"] }
    var playButton:    XCUIElement { app.buttons["slideshow_play_button"] }
    var backButton:    XCUIElement { app.buttons["slideshow_back_button"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        videoPlayer.waitForExistence(timeout: timeout)
    }

    func tapPlay()     { playButton.tap() }
}

// MARK: - PermissionAlertHelper

/// Handles system permission alerts that interrupt user flows.
enum PermissionAlertHelper {
    static func allowIfPresent(in app: XCUIApplication, timeout: TimeInterval = 3) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow", "OK", "Allow While Using App"] {
            let btn = springboard.buttons[label]
            if btn.waitForExistence(timeout: timeout) { btn.tap(); return }
        }
    }

    static func denyIfPresent(in app: XCUIApplication, timeout: TimeInterval = 3) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Don't Allow", "Deny"] {
            let btn = springboard.buttons[label]
            if btn.waitForExistence(timeout: timeout) { btn.tap(); return }
        }
    }
}
