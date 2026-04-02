# Apple Cloud Database (CloudKit) Integration

DreamFlow uses CloudKit on iOS for privacy-first user data and sync workflows.

## iOS App Requirements

- Enable iCloud capability in Xcode.
- Enable CloudKit for the app target.
- Set the container identifier to `CLOUDKIT_CONTAINER_IDENTIFIER`.
- Use private database for user-specific records and shared database for invite/circle sharing flows.

## Suggested Record Types

- `DFUserProfile`
- `DFCircle`
- `DFCircleMember`
- `DFLocationEvent`
- `DFGeofence`
- `DFAlert`
- `DFSOSIncident`

## Backend/Middleware Role

CloudKit is directly consumed by iOS app code for user-owned records.
Middleware/backend remains source of truth for cross-platform operational state:

- Circle policy enforcement
- Push orchestration
- Analytics ingestion
- Audit and abuse protection

## Sync Pattern

1. iOS writes user-approved records to CloudKit.
2. Middleware receives summarized ingestion events for operational processing.
3. Worker pipelines fan out alerts and timeline materializations.
4. Data platform stores normalized telemetry for insights.
