# World Class Scholars Web Runtime

The public Vercel site now supports durable enquiry capture and
transactional email forwarding from the serverless `book-call`
endpoint.

## Enquiry Persistence

The endpoint will persist leads into a Postgres-compatible database
when either of these is configured:

- `DATABASE_URL`
- or the split variables `DATABASE_HOST`, `DATABASE_PORT`,
  `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD`

This works with Neon and Supabase Postgres. On first write, the
function creates the `wcs_book_call_leads` table automatically.

Recommended runtime flags:

- `DATABASE_SSL=true`
- `DATABASE_SSL_REJECT_UNAUTHORIZED=true`

Stored columns include lead identity, message, source, request
metadata, and notification status.

## Email Forwarding

Transactional email forwarding is enabled when these variables are present:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`

Optional overrides:

- `ENQUIRY_NOTIFICATION_TO`
- `ENQUIRY_NOTIFICATION_FROM`
- `ENQUIRY_NOTIFICATION_SUBJECT_PREFIX`

If `ENQUIRY_NOTIFICATION_TO` is unset, notifications default to `christopher.appiahthompson@myworldclass.org`.

## Local Setup

1. Copy `.env.example` to `.env.local`.
2. Add your Postgres and SMTP credentials.
3. Run `npm install`.
4. Run `npm run build` or `npm run dev`.

## Vercel Setup

Add the same variables to the linked Vercel project before deploying:

```bash
vercel env add DATABASE_URL production
vercel env add DATABASE_SSL production
vercel env add SMTP_USER production
vercel env add SMTP_PASS production
vercel env add ENQUIRY_NOTIFICATION_TO production
```

Then redeploy the site so the serverless function receives the new secrets.

## Behaviour Without Secrets

If no database or SMTP credentials are configured, the endpoint still
accepts the submission and returns delivery metadata showing which
parts were skipped. This keeps the public form stable while secrets are
being added, but it is not durable until the database variables are
set.