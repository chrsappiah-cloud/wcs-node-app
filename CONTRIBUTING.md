# Contributing to GeoWCS

We welcome contributions from the community! This document outlines how to contribute code, documentation, and feedback.

---

## Code of Conduct

Be respectful, inclusive, and professional. We have zero tolerance for harassment, discrimination, or unsafe behavior.

---

## Getting Started

### Fork & Clone

```bash
# Fork on GitHub
# Clone your fork
git clone https://github.com/YOUR-USERNAME/geowcs.git
cd geowcs

# Add upstream remote
git remote add upstream https://github.com/geowcs/geowcs.git
```

### Local Development Setup

```bash
# Install dependencies (see DEPLOYMENT.md for detailed steps)
cd dreamflow/apps/api
npm install

# Copy environment template
cp .env.example .env.local

# Edit .env.local with your test credentials

# Start dev servers
npm run start:dev
```

### iOS Development

```bash
# Open in Xcode
open GeoWCS.xcodeproj

# Or build from command line
xcodebuild build -project GeoWCS.xcodeproj -scheme GeoWCS -destination "platform=iOS Simulator,name=iPhone 17 Pro Max"
```

---

## Code Style

### Swift

```swift
// ✅ Good
func startRecording() {
    do {
        try audioSession.setCategory(.record)
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.record()
    } catch {
        lastError = .recordingFailed(error.localizedDescription)
    }
}

// ❌ Avoid
func startRecording(){
    audioRecorder?.record()
}
```

**Guidelines**:
- Use `@MainActor` for UI-related classes
- Use `@Published` for observable properties
- Error handling: Always catch and log
- Naming: camelCase for variables/functions, PascalCase for types
- Comments: Explain *why*, not *what*

### TypeScript / NestJS

```typescript
// ✅ Good
@Controller('circles')
@UseGuards(JwtAuthGuard)
export class CirclesController {
  constructor(private circlesService: CirclesService) {}

  @Post()
  async create(@Body() createCircleDto: CreateCircleDto) {
    return this.circlesService.create(createCircleDto);
  }
}

// ❌ Avoid
export class CirclesController {
  create(data) { /* ... */ }
}
```

**Guidelines**:
- Use decorators: `@Controller`, `@UseGuards`, `@Post`
- Type everything: No `any`
- Error handling: Use custom exceptions
- Naming: camelCase for properties/methods, PascalCase for classes/interfaces
- Linting: `npm run lint:fix`

---

## Commit Conventions

We use Conventional Commits for clear history.

### Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (no logic change)
- `refactor`: Refactoring
- `perf`: Performance improvement
- `test`: Tests
- `chore`: Build/dependency updates

### Examples

```
feat: add audio evidence recording to safety toolkit

- Implement AVAudioRecorder with MPEG-4 AAC codec
- Add AudioRecorderView with waveform visualization
- Integrate with ContentView safety section
- Persist metadata to UserDefaults

Closes #42
```

```
fix: resolve geofence alert delivery failures

- Correct APNs payload structure
- Handle CoreLocation permission edge cases
- Add retry logic for failed POSTs

Fixes #38
```

---

## Branch Naming

```
feature/audio-recorder
fix/geofence-precision
docs/deployment-guide
refactor/auth-manager
```

---

## Testing

### Required Testing Workflow

Follow the fused testing model in `TESTING_FUSION_HANDBOOK.md` for all new features and fixes.

Required local checks before opening a PR:

```bash
bash scripts/run-tests.sh unit
bash scripts/run-tests.sh integration
```

When changing DeArtWCS / RokMaxCreative flows, also run:

```bash
bash scripts/run-tests.sh dearts
```

UI smoke tests are required on `master` / release merges and should be run locally for high-risk UI changes:

```bash
bash scripts/run-tests.sh ui
```

Regression rule: every production bug fix must include at least one test that fails before the fix and passes after it.

### Test Support Conventions

Shared test helpers should go under `GeoWCSTests/Support/`:

- `Fixtures/` for static JSON and fixture-loading utilities
- `Builders/` for reusable test data builders
- `Fakes/` for lightweight in-memory implementations
- `Spies/` for interaction recording helpers
- `Mocks/` for strict interaction-based doubles

Prefer reusing support helpers before introducing new ad-hoc test utilities in individual test files.

### Before Submitting

```bash
# NestJS
cd dreamflow/apps/api
npm test
# Expected: all pass

# Swift
xcodebuild build -project GeoWCS.xcodeproj -scheme GeoWCS
# Expected: BUILD SUCCEEDED

# Linting
npm run lint
```

### Writing Tests

**NestJS**:
```typescript
describe('AlertsService', () => {
  let service: AlertsService;

  beforeEach(() => {
    service = new AlertsService(mockRepository);
  });

  it('should create alert with valid circleId', async () => {
    const alert = await service.create({
      circleId: 'circle-123',
      alertType: 'arrival'
    });

    expect(alert.id).toBeDefined();
    expect(alert.timestamp).toBeDefined();
  });
});
```

**Swift**:
```swift
class AudioRecorderManagerTests: XCTestCase {
  var manager: AudioRecorderManager!

  override func setUp() {
    manager = AudioRecorderManager()
  }

  func testStartRecording() {
    manager.startRecording()
    XCTAssertTrue(manager.isRecording)
  }
}
```

---

## Pull Request Process

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature
```

### 2. Make Changes

```bash
# Commit frequently with meaningful messages
git commit -m "feat: add feature description"
```

### 3. Push to Your Fork

```bash
git push origin feature/your-feature
```

### 4. Open Pull Request

- **Title**: Clear, descriptive ("Add audio recording to safety toolkit")
- **Description**: 
  - What does this do?
  - Why is this needed?
  - Any breaking changes?
  - Related issues (#42)
- **Checklist**:
  - [ ] Tests pass locally
  - [ ] No console warnings
  - [ ] Documentation updated
  - [ ] Code follows style guide
  - [ ] No secrets in code

### 5. Address Feedback

- Respond to comments promptly
- Push fixes as new commits (don't rebase until approved)
- Request re-review after changes

### 6. Merge

Once approved, maintainers will merge via GitHub UI.

---

## IDE Setup

### Xcode (Swift)

```bash
# Install SwiftFormat
brew install swiftformat

# Configure in Xcode
# Build Phases → New Run Script Phase
swiftformat .
```

### VSCode (TypeScript)

Create `.vscode/settings.json`:

```json
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

---

## Documentation

### README Updates

- Add feature description + screenshots
- Update feature matrix
- Add API endpoint examples

### Inline Comments

```swift
// ✅ Good: Explains *why*
// Use @MainActor to ensure UI updates on main thread
@MainActor
final class AudioRecorderManager: ObservableObject {

// ❌ Bad: Obvious from code
// Initialize recorder
let recorder = AVAudioRecorder()
```

### Commit Documentation

```
git log --oneline --graph --all
```

---

## Reporting Issues

### Bug Report

```markdown
**Describe the bug**
Audio recorder fails to start on iOS 16.

**Steps to reproduce**
1. Grant microphone permission
2. Tap "Start Recording"
3. Button remains blue, no recording starts

**Expected behavior**
Red "Stop Recording" button appears, waveform animates.

**Actual behavior**
Button stays blue, console shows:
```
Error: Failed to start recording: The operation couldn't be completed. (NSOSStatusErrorDomain error 561015905.)
```

**Environment**
- iOS: 16.7.2
- Device: iPhone 15 Pro Max
- Build: GeoWCS v1.0.0 (Build 42)

**Screenshots**
[Screenshot showing frozen button]
```

### Feature Request

```markdown
**Describe the feature**
Add undo button for accidental SOS activation.

**Use case**
Currently, long-pressing SOS sends alert immediately with no way to cancel.

**Proposed solution**
After SOS pressed, show 5-second countdown with "Cancel" button.

**Alternatives**
- Require second tap to confirm
- Require holding for 2 seconds instead of 1

**Additional context**
Community has requested this 3+ times.
```

---

## Development Workflow

### Example: Adding a New Feature

```bash
# 1. Create feature branch
git checkout -b feature/persistent-location-history

# 2. Update backend (NestJS)
cd dreamflow/apps/api
cat > src/location-history/location-history.service.ts << 'EOF'
// New service implementation
EOF

# 3. Add tests
cat > src/location-history/location-history.service.spec.ts << 'EOF'
// Test implementation
EOF

npm test

# 4. Update iOS
# Edit GeoWCS/LocationTracker.swift to store history

# 5. Commit
git add .
git commit -m "feat: add persistent location history

- LocationHistoryService queries last 30 days
- LocationTracker stores locally
- ContentView displays timeline"

# 6. Push
git push origin feature/persistent-location-history

# 7. Open PR on GitHub
```

---

## Security

### Do NOT commit:

- `.env` files
- API keys, tokens, secrets
- Passwords
- Private keys (`.pem`, `.key`)

### Reporting Security Issues

**Do NOT open public issue!**

Email: security@geowcs.dev with:
- Vulnerability description
- Steps to reproduce
- Potential impact
- Suggested fix (if you have one)

---

## Community

- **Slack**: [Join community](https://geowcs-community.slack.com)
- **GitHub Discussions**: [Ask questions](https://github.com/geowcs/geowcs/discussions)
- **Email**: hello@geowcs.dev

---

## Recognition

Contributors are recognized monthly in:
- GitHub CONTRIBUTORS.md
- Release notes
- Company blog

---

## Legal

By contributing, you agree that your code will be licensed under the same license as this repository (see LICENSE file).

---

Thank you for contributing to GeoWCS! 🙏
