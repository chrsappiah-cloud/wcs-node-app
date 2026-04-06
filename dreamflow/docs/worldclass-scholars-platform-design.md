# YourWorld Class Scholars Platform Design

## Vision

Create a clean, modern digital health and arts therapy platform inspired by Ether-style product experiences, optimized for rapid MVP launches and secure scale-up.

## Product Experience Direction

- A minimalist visual system with dark and light themes.
- Glassmorphism cards and layered backgrounds for depth.
- Bold typography using modern sans-serif families.
- Hero section with direct business CTA: Book a Free Call.
- Subtle motion for scroll and hover interactions.

## Layered Architecture

| Layer | Tech | Purpose |
| --- | --- | --- |
| Frontend | React + Tailwind CSS + TypeScript | Responsive web UI, service grid, dashboards, CTA flows |
| Middleware | Node.js (NestJS) REST APIs | Request validation, auth, orchestration, integrations |
| Backend + AI | Node.js + Python workers (OpenAI/PyTorch ready) | Therapy workflows, AI insights, automation pipelines |
| Database | PostgreSQL or MongoDB | User profiles, therapy sessions, outcomes, audit trails |
| Hosting | AWS (EC2/ECS, S3, CloudFront, RDS/DocumentDB) | Scale, reliability, global delivery |
| Mobile Integration | iOS + Flutter clients | Native care experiences using shared API contracts |

## Frontend Design System

- Mobile-first layout with responsive breakpoints.
- Semantic structure using accessible HTML5 sections.
- Reusable React components for hero, phase cards, and service cards.
- Tailwind utility-driven styling for speed and consistency.
- Theme persistence using local storage.

## API and Middleware Design

### Core endpoints

- GET /wcs-platform/landing-content
- POST /wcs-platform/book-call
- GET /wcs-platform/therapy-sessions
- POST /wcs-platform/therapy-sessions
- POST /wcs-platform/ai/insights

### Responsibilities

- Validate payloads with DTOs and class-validator.
- Isolate booking, therapy, and insight generation logic in service modules.
- Use role-aware auth middleware when API_AUTH_REQUIRED is enabled.

## Data Model (Initial MVP)

### Lead

- id
- name
- email
- phone
- notes
- createdAt

### TherapySession

- id
- participantId
- scheduledFor
- modality
- therapeuticGoal
- status

### AIInsight

- participantId
- reflection
- signal
- recommendation
- generatedAt

## Security and Compliance Baseline

- TLS in transit and managed encryption at rest.
- Least-privilege IAM roles for backend services.
- Audit logs for auth and clinical workflow events.
- Input validation and request throttling at API layer.
- Segregated environments for dev, staging, and production.

## AWS Deployment Blueprint

- CloudFront + S3 for frontend assets.
- ECS Fargate or EC2 for Node.js API runtime.
- RDS PostgreSQL or DocumentDB based on data modeling decision.
- Secrets Manager for credentials and signing keys.
- CloudWatch for API and app monitoring.

## CI/CD (GitHub Actions)

- Trigger on pull requests and main branch merges.
- Steps: install, type-check, test, build, security scan, deploy.
- Environment-gated deployments with manual production approvals.

## Near-Term Build Phases

1. Discovery and UX prototype in Figma
2. MVP frontend and booking APIs
3. Therapy session workflows and analytics
4. AI-assisted features and mobile integration hardening
5. Compliance readiness and production scale-out
