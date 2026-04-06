# GeoWCSTests Support

Shared test support types live here.

- `Fixtures/` stores static payloads and sample data.
- `Builders/` stores test data builders and object mothers.
- `Fakes/` stores lightweight in-memory implementations.
- `Spies/` stores recording doubles for interaction assertions.
- `Mocks/` stores strict interaction-based doubles when needed.

Keep support code small, deterministic, and reusable across unit, integration, and contract-boundary tests.