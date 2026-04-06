# Fixtures

Store static JSON payloads, serialized responses, and sample values used across tests.

Current sample fixtures:

- `sample_profile.json` for `FixtureLoader` utility decoding tests.
- `accessibility_profile.json` for `AccessibilityProfile` domain fixture decoding tests.
- `accessibility_profile_malformed.json` for negative-path decode failure assertions.
- `media_asset.json` for integration tests that decode and persist `MediaAsset` values.
- `media_asset_malformed.json` for negative-path decode failure assertions.
- `activity_prompt.json` for speech synthesis integration tests that decode and execute `CreateSpeechPrompt`.
- `activity_prompt_malformed.json` for negative-path decode failure assertions.
