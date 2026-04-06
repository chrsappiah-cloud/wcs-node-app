-- WCS platform MVP tables for PostgreSQL (RDS/local Postgres)
-- Apply with: psql "$DATABASE_URL" -f infrastructure/sql/wcs_platform_tables.sql

CREATE TABLE IF NOT EXISTS wcs_book_call_leads (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  notes TEXT,
  source TEXT NOT NULL DEFAULT 'vercel-web-api',
  submitted_path TEXT,
  ip_address TEXT,
  user_agent TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  notification_status TEXT NOT NULL DEFAULT 'pending',
  notification_error TEXT,
  notification_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wcs_consult_leads (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  channel TEXT,
  details TEXT,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wcs_therapy_sessions (
  id TEXT PRIMARY KEY,
  participant_id TEXT NOT NULL,
  scheduled_for TIMESTAMPTZ NOT NULL,
  modality TEXT NOT NULL,
  therapeutic_goal TEXT,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wcs_therapy_sessions_scheduled_for
  ON wcs_therapy_sessions (scheduled_for DESC);

CREATE INDEX IF NOT EXISTS idx_wcs_book_call_leads_created_at
  ON wcs_book_call_leads (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_wcs_consult_leads_submitted_at
  ON wcs_consult_leads (submitted_at DESC);
