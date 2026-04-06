# WCS Platform CI/CD Setup

## Workflow

The pipeline is defined at:

- .github/workflows/wcs-platform-ci.yml

## What it does

1. Pull requests and main-branch pushes:
- Install dependencies
- Build API (@dreamflow/api)
- Build frontend (@dreamflow/web)
- Upload web dist artifact

2. Main-branch deployments:
- Rebuild web app
- Optionally sync to S3
- Optionally invalidate CloudFront

If AWS secrets are not configured, deployment is skipped and CI still validates the build.

## Required secrets for AWS deploy

- AWS_ROLE_TO_ASSUME
- AWS_REGION
- AWS_S3_BUCKET
- AWS_CLOUDFRONT_DISTRIBUTION_ID (optional but recommended)

## Runtime environment variables

API PostgreSQL settings:

- DATABASE_URL
- DATABASE_SSL
- DATABASE_SSL_REJECT_UNAUTHORIZED

Web API base URL:

- VITE_API_BASE_URL

## Database schema bootstrap

Apply the MVP schema to PostgreSQL:

- infrastructure/sql/wcs_platform_tables.sql

Example:

- psql "$DATABASE_URL" -f infrastructure/sql/wcs_platform_tables.sql

## Suggested production topology

- Static frontend: S3 + CloudFront
- API runtime: ECS Fargate or EC2
- Database: RDS PostgreSQL
- Optional previews: Vercel for frontend preview builds
