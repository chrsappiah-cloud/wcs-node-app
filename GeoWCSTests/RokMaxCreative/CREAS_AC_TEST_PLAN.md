# DeArtsWCS CrEAS-AC Test Plan Mapping

This plan maps each CrEAS-AC checklist item to concrete test coverage across unit, integration, and UI tests.

## Test Sources

- Unit scaffold: `DeArtsWCSTDDScaffoldTests`
- App-type scaffold: `DeArtsWCSAppTypesScaffoldTests`
- Integration suite: `DeArtsWCSIntegrationTests`
- UI suite: `DeArtsWCSCriticalFlowsUITests`

## Context Checklist Mapping

| Checklist Item | Unit Test | Integration Test | UI Test |
| --- | --- | --- | --- |
| Offline mode caches assets/session data | `testOfflineCanvas_savesEvery30Seconds_redScaffold` | `testSessionProgress_persistsWhileAudioIsPlaying` | `testOfflineModeShowsCacheIndicator_scaffold` |
| Accessibility auto-adjust for low vision | `testAppModel_initialState_scaffold` | N/A | `testLargeTouchTargetsForPrimaryActions_scaffold` |
| Caregiver dashboard within 2 taps | N/A | N/A | `testCaregiverDashboardAccessibleWithinTwoTaps_scaffold` |
| Session timer visible and calm | `testArtSessionTimer_formatsDurationAsMMSS` | N/A | `testSessionStartsWithinTwoTaps_scaffold` |
| Orientation supports comfortable canvas use | N/A | N/A | `testCanvasPinchAndDrawFlow_scaffold` |

## Realism Checklist Mapping

| Checklist Item | Unit Test | Integration Test | UI Test |
| --- | --- | --- | --- |
| Natural drawing feel | N/A | N/A | `testCanvasPinchAndDrawFlow_scaffold` |
| Stroke-reactive media behavior | `testPlayTherapyAudio_completesIn5Minutes` | `testSessionProgress_persistsWhileAudioIsPlaying` | `testMoodChangeUpdatesAmbientState_scaffold` |
| Mood change updates ambience | `testArtSessionTimer_pausesOnMoodChange` | N/A | `testMoodChangeUpdatesAmbientState_scaffold` |
| Pinch-to-zoom canvas remains fluid | N/A | N/A | `testCanvasPinchAndDrawFlow_scaffold` |
| Autosave every 30 seconds | `testOfflineCanvas_savesEvery30Seconds` | `testOfflineCanvas_savesEvery30Seconds` | `testOfflineModeShowsCacheIndicator_scaffold` |

## Engagement Checklist Mapping

| Checklist Item | Unit Test | Integration Test | UI Test |
| --- | --- | --- | --- |
| Session starts in <= 2 taps | N/A | `testCompleteCreativeSessionWorkflow` | `testSessionStartsWithinTwoTaps_scaffold` |
| Rotating prompts maintain focus | `testTextToImageService_generatesImage_scaffold` | `testGenerateImageWorkflow` | N/A |
| Voice guidance appears | N/A | N/A | `testVoiceOverNarrativeVisible_scaffold` |
| Caregiver sees live mood trends | `testCaregiverDashboard_liveMoodUpdates` | N/A | `testCaregiverDashboardAccessibleWithinTwoTaps_scaffold` |
| Gallery evolution is visible | `testAppModel_tabTransitions_scaffold` | `testCompleteCreativeSessionWorkflow` | `testCanvasPinchAndDrawFlow_scaffold` |

## Aesthetics Checklist Mapping

| Checklist Item | Unit Test | Integration Test | UI Test |
| --- | --- | --- | --- |
| Pastel dementia-friendly palette | N/A | N/A | `testMoodChangeUpdatesAmbientState_scaffold` |
| Smooth animations and motion comfort | N/A | N/A | `testCanvasPinchAndDrawFlow_scaffold` |
| Mood-based visual state shifts | `testArtSessionTimer_pausesOnMoodChange` | N/A | `testMoodChangeUpdatesAmbientState_scaffold` |
| Rounded readable typography | N/A | N/A | `testVoiceOverNarrativeVisible_scaffold` |
| Audio ducking and calm output | `testPlayTherapyAudio_completesIn5Minutes_redScaffold` | `testSessionProgress_persistsWhileAudioIsPlaying` | N/A |

## Storytelling Checklist Mapping

| Checklist Item | Unit Test | Integration Test | UI Test |
| --- | --- | --- | --- |
| Session tagged with mood/theme | `testAppModel_initialState_scaffold` | `testCompleteCreativeSessionWorkflow` | `testMoodChangeUpdatesAmbientState_scaffold` |
| Auto-generated session summaries | N/A | `testCompleteCreativeSessionWorkflow` | `testVoiceOverNarrativeVisible_scaffold` |
| Timestamped timeline progression | N/A | `testCompleteCreativeSessionWorkflow` | `testSessionStartsWithinTwoTaps_scaffold` |
| VoiceOver narrative recaps | N/A | N/A | `testVoiceOverNarrativeVisible_scaffold` |
| Clinician export package readiness | N/A | `testPaintingCreationAndSave` | N/A |

## Coverage Targets

- Unit: 70% of suite, 80%+ logic coverage on multimedia-critical modules.
- Integration: 20% of suite, all critical data and media flows.
- UI: 10% of suite, all patient/caregiver key journeys.

## Promotion Rules

1. Red tests are written first for each new requirement.
2. Green implementation is minimal and behavior-focused.
3. Refactor keeps tests green while improving readability/maintainability.
4. CI blocks merge when critical-path tests fail.
