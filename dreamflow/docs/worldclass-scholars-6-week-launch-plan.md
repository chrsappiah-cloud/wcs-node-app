# World Class Scholars 6-Week MVP Launch Plan

## Target Outcome

Launch a production-ready MVP for Brisbane digital health and arts therapy with:

- React + Tailwind frontend
- Node.js middleware/backend
- PostgreSQL on AWS RDS
- CI/CD via GitHub Actions
- Marketing funnels integrated from day one

## Week-by-Week Plan

### Week 1: Discovery + Architecture Lock

- Finalize care workflows, compliance boundaries, and funnel goals.
- Confirm architecture:
  - Frontend: React + Tailwind + Plotly dashboards
  - Middleware: Node/Nest or Express APIs
  - Data: PostgreSQL (sessions, leads, funnel attribution)
  - Hosting: AWS S3 + CloudFront (web), EC2/ECS (API), RDS (DB)
- Define KPIs:
  - Consult conversion rate
  - Session completion trend
  - Funnel stage drop-off

### Week 2: UX + Brand System + Prototype

- Ether-inspired visual system:
  - Dark slate-purple-indigo gradients
  - Glassmorphism cards
  - Inter typography
  - Parallax hero and motion guidelines
- Build and validate prototype:
  - Hero + trust signals
  - 5-phase process
  - Consultation form
  - Dashboard and funnel sections

### Week 3: Core Frontend + API Contracts

- Implement production React frontend sections.
- Build API endpoints:
  - /wcs-platform/landing-content
  - /wcs-platform/book-call
  - /wcs-platform/consult
  - /wcs-platform/therapy-sessions
  - /wcs-platform/metrics
- Add validation and baseline auth.

### Week 4: Data + Integrations

- Provision PostgreSQL schema:
  - leads
  - consult_requests
  - therapy_sessions
  - dashboard_metrics
  - funnel_events
- Integrate OpenAI/Python pipeline placeholders for art/music features.
- Add GA4 + marketing pixel events.

### Week 5: Funnel Automation + Deployment

- Implement growth funnel workflows:
  - PPC landing variants
  - Email capture and nurture triggers
  - Testimonial carousel + urgency CTA
- Deploy:
  - Static web to S3 + CloudFront
  - API to EC2 or ECS
  - DB to RDS PostgreSQL
- Configure Vercel preview environment for fast design iteration.

### Week 6: Hardening + Launch

- Security and compliance hardening:
  - Encryption at rest/in transit
  - Audit logging
  - Secret rotation
- Test strategy:
  - Frontend build and smoke tests
  - API build and contract validation
  - Funnel conversion QA
- Launch checklist and investor demo packaging.

## Marketing Funnel Baseline

- Top funnel: PPC + SEO traffic to parallax hero landing.
- Mid funnel: consultation form + trust badges + testimonials.
- Bottom funnel: booking CTA + nurture email sequence + dashboard proof.

## CI/CD Baseline (GitHub Actions)

- Pull request:
  - install
  - lint
  - type-check
  - build:web
  - build:api
- Main branch:
  - deploy static web
  - deploy API
  - run DB migration checks

## Architecture Snapshot

| Layer | Stack | Notes |
| --- | --- | --- |
| Frontend | React, Tailwind, Plotly | Responsive web + analytics visuals |
| Middleware | Node.js/Nest or Express | Auth, consult APIs, funnel ingestion |
| Backend | Node.js + Python | AI integrations and business workflows |
| Database | PostgreSQL (RDS) | Session, consult, and compliance data |
| Hosting | AWS + Vercel preview | CloudFront/S3 static + API hosting |

## Launch-Readiness Criteria

- Core consultation and therapy endpoints stable.
- KPI dashboards render with live API data.
- Funnel conversion instrumentation active.
- Security baseline and audit requirements documented.
- Team operational runbook and ownership finalized.
