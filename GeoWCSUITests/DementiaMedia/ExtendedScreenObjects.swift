//
//  ExtendedScreenObjects.swift
//  GeoWCSUITests – DementiaMedia Extended Screen Objects
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Extends the Phase 1 screen-object catalogue with 5 new screens
//  introduced by the guided-activities module and caregiver workflows.
//

import XCTest

// MARK: - TextToAudioScreen

/// Caregiver screen for composing a spoken-word prompt using TTS synthesis.
struct TextToAudioScreen {
    let app: XCUIApplication

    var promptField:       XCUIElement { app.textViews["tts_prompt_text_view"] }
    var calmVoiceButton:   XCUIElement { app.buttons["tts_calm_voice_button"] }
    var previewButton:     XCUIElement { app.buttons["tts_preview_button"] }
    var saveButton:        XCUIElement { app.buttons["tts_save_button"] }
    var backButton:        XCUIElement { app.buttons["tts_back_button"] }
    var promptPreviewLabel: XCUIElement { app.staticTexts["tts_preview_label"] }
    var charCountLabel:    XCUIElement { app.staticTexts["tts_char_count_label"] }
    var errorLabel:        XCUIElement { app.staticTexts["tts_error_label"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        promptField.waitForExistence(timeout: timeout)
    }

    /// Types a prompt into the text view.
    func enterPrompt(_ text: String) {
        promptField.tap()
        promptField.typeText(text)
    }

    /// Selects the calm voice option (required for dementia safety).
    func selectCalmVoice() { calmVoiceButton.tap() }

    /// Starts TTS preview playback.
    func tapPreview() { previewButton.tap() }

    /// Saves the synthesised audio prompt.
    func tapSave() { saveButton.tap() }

    /// Waits for the preview playback label to appear.
    func waitForPreviewLabel(timeout: TimeInterval = 5) -> Bool {
        promptPreviewLabel.waitForExistence(timeout: timeout)
    }

    /// Waits for a save-confirmation signal.
    func waitForSaveConfirmation(timeout: TimeInterval = 5) -> Bool {
        app.staticTexts["Saved"].waitForExistence(timeout: timeout)
    }

    /// Waits for a validation error to appear after bad input.
    func waitForError(timeout: TimeInterval = 3) -> Bool {
        errorLabel.waitForExistence(timeout: timeout)
    }
}

// MARK: - SlideshowBuilderScreen

/// Caregiver screen for assembling a photo slideshow with optional narration.
struct SlideshowBuilderScreen {
    let app: XCUIApplication

    var addPhotosButton:    XCUIElement { app.buttons["slideshow_builder_add_photos"] }
    var narrationField:     XCUIElement { app.textFields["slideshow_builder_narration_field"] }
    var exportButton:       XCUIElement { app.buttons["slideshow_builder_export_button"] }
    var backButton:         XCUIElement { app.buttons["slideshow_builder_back_button"] }
    var photoGrid:          XCUIElement { app.collectionViews["slideshow_builder_photo_grid"] }
    var exportProgressView: XCUIElement { app.progressIndicators["slideshow_builder_progress"] }
    var exportErrorLabel:   XCUIElement { app.staticTexts["slideshow_builder_error_label"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        addPhotosButton.waitForExistence(timeout: timeout)
    }

    /// Opens the system photo picker.
    func tapAddPhotos() { addPhotosButton.tap() }

    /// Selects the photo at the given index in the grid (after picker closes).
    func selectPhoto(at index: Int) {
        photoGrid.cells.element(boundBy: index).tap()
    }

    /// Types into the optional narration text field.
    func enterNarration(_ text: String) {
        narrationField.tap()
        narrationField.typeText(text)
    }

    /// Starts the slideshow export render.
    func tapExport() { exportButton.tap() }

    /// Waits for the export completion indicator to appear.
    func waitForExportSuccess(timeout: TimeInterval = 30) -> Bool {
        app.staticTexts["Export complete"].waitForExistence(timeout: timeout)
    }

    /// Waits for a storage-full or other export error.
    func waitForExportError(timeout: TimeInterval = 10) -> Bool {
        exportErrorLabel.waitForExistence(timeout: timeout)
    }

    /// Number of photos currently in the builder grid.
    var photoCount: Int { photoGrid.cells.count }
}

// MARK: - ActivityPromptScreen

/// Patient facing screen that guides through a single guided-activity session.
struct ActivityPromptScreen {
    let app: XCUIApplication

    var startButton:      XCUIElement { app.buttons["activity_start_button"] }
    var markCompleteButton: XCUIElement { app.buttons["activity_mark_complete_button"] }
    var skipStepButton:   XCUIElement { app.buttons["activity_skip_step_button"] }
    var pauseButton:      XCUIElement { app.buttons["activity_pause_button"] }
    var resumeButton:     XCUIElement { app.buttons["activity_resume_button"] }
    var currentStepLabel: XCUIElement { app.staticTexts["activity_current_step_label"] }
    var progressLabel:    XCUIElement { app.staticTexts["activity_progress_label"] }
    var breakBanner:      XCUIElement { app.staticTexts["activity_break_banner"] }
    var completionBanner: XCUIElement { app.staticTexts["activity_completion_banner"] }
    var backButton:       XCUIElement { app.buttons["activity_back_button"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        startButton.waitForExistence(timeout: timeout)
    }

    /// Taps the start-activity button to begin the guided session.
    func tapStartActivity() { startButton.tap() }

    /// Marks the current step as complete.
    func tapMarkComplete() { markCompleteButton.tap() }

    /// Caregiver skip of the current step.
    func tapSkipStep() { skipStepButton.tap() }

    /// Pauses the session (caregiver override).
    func tapPause() { pauseButton.tap() }

    /// Resumes from a break or caregiver pause.
    func tapResume() { resumeButton.tap() }

    /// Waits for the auto-break banner to appear.
    func waitForBreakBanner(timeout: TimeInterval = 5) -> Bool {
        breakBanner.waitForExistence(timeout: timeout)
    }

    /// Waits for the session-completion banner.
    func waitForCompletionBanner(timeout: TimeInterval = 10) -> Bool {
        completionBanner.waitForExistence(timeout: timeout)
    }
}

// MARK: - LibraryScreen

/// Full-featured media library screen with deletion support.
struct LibraryScreen {
    let app: XCUIApplication

    var itemsGrid:       XCUIElement { app.collectionViews["library_items_grid"] }
    var emptyStateLabel: XCUIElement { app.staticTexts["library_empty_state_label"] }
    var deleteButton:    XCUIElement { app.buttons["library_delete_button"] }
    var confirmDeleteButton: XCUIElement { app.buttons["library_confirm_delete_button"] }
    var cancelDeleteButton:  XCUIElement { app.buttons["library_cancel_delete_button"] }
    var backButton:      XCUIElement { app.buttons["library_back_button"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        itemsGrid.waitForExistence(timeout: timeout)
            || emptyStateLabel.waitForExistence(timeout: timeout)
    }

    /// Number of items currently visible in the library.
    var itemCount: Int { itemsGrid.cells.count }

    /// Opens the most recently saved item (index 0 in reverse-chronological order).
    func openLatestItem() {
        itemsGrid.cells.element(boundBy: 0).tap()
    }

    /// Taps the item at the given grid index.
    func tapItem(at index: Int) {
        itemsGrid.cells.element(boundBy: index).tap()
    }

    /// Initiates the two-step delete workflow for the selected item.
    func tapDelete() { deleteButton.tap() }

    /// Confirms deletion in the two-step workflow.
    func confirmDelete() { confirmDeleteButton.tap() }

    /// Cancels the pending deletion.
    func cancelDelete() { cancelDeleteButton.tap() }

    /// Waits for the confirmation alert / sheet to appear.
    func waitForDeleteConfirmation(timeout: TimeInterval = 3) -> Bool {
        confirmDeleteButton.waitForExistence(timeout: timeout)
    }

    /// Waits for the empty-state label (all items deleted or no items yet).
    func waitForEmptyState(timeout: TimeInterval = 5) -> Bool {
        emptyStateLabel.waitForExistence(timeout: timeout)
    }
}

// MARK: - SettingsScreen

/// Application settings screen with patient-mode and privacy controls.
struct SettingsScreen {
    let app: XCUIApplication

    var patientModeToggle:    XCUIElement { app.switches["settings_patient_mode_toggle"] }
    var caregiverModeToggle:  XCUIElement { app.switches["settings_caregiver_mode_toggle"] }
    var privacySettingsButton: XCUIElement { app.buttons["settings_privacy_button"] }
    var versionLabel:         XCUIElement { app.staticTexts["settings_version_label"] }
    var resetButton:          XCUIElement { app.buttons["settings_reset_button"] }
    var backButton:           XCUIElement { app.buttons["settings_back_button"] }

    @discardableResult
    func waitForAppearance(timeout: TimeInterval = 5) -> Bool {
        patientModeToggle.waitForExistence(timeout: timeout)
    }

    /// Toggles the patient-mode switch.
    func togglePatientMode() { patientModeToggle.tap() }

    /// Toggles the caregiver-mode switch.
    func toggleCaregiverMode() { caregiverModeToggle.tap() }

    /// Opens the privacy settings sub-screen.
    func tapPrivacySettings() { privacySettingsButton.tap() }

    /// Returns true if patient mode is currently enabled.
    func isPatientModeOn() -> Bool {
        patientModeToggle.value as? String == "1"
    }

    /// Returns true if caregiver mode is currently enabled.
    func isCaregiverModeOn() -> Bool {
        caregiverModeToggle.value as? String == "1"
    }
}
