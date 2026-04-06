const { Pool } = require('pg');
const nodemailer = require('nodemailer');

const DEFAULT_ENQUIRY_RECIPIENT = 'christopher.appiahthompson@myworldclass.org';
const DEFAULT_EMAIL_SUBJECT_PREFIX = 'World Class Scholars enquiry';

let pool;
let schemaPromise;

function buildDatabaseUrl() {
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  const host = process.env.DATABASE_HOST;
  const port = process.env.DATABASE_PORT || '5432';
  const database = process.env.DATABASE_NAME;
  const user = process.env.DATABASE_USER;
  const password = process.env.DATABASE_PASSWORD;

  if (!host || !database || !user || !password) {
    return null;
  }

  return `postgresql://${encodeURIComponent(user)}:${encodeURIComponent(password)}@${host}:${port}/${database}`;
}

function getPool() {
  const connectionString = buildDatabaseUrl();
  if (!connectionString) {
    return null;
  }

  if (!pool) {
    pool = new Pool({
      connectionString,
      ssl:
        process.env.DATABASE_SSL === 'true'
          ? {
              rejectUnauthorized: process.env.DATABASE_SSL_REJECT_UNAUTHORIZED !== 'false'
            }
          : undefined
    });
  }

  return pool;
}

async function ensureSchema() {
  const activePool = getPool();
  if (!activePool) {
    return false;
  }

  if (!schemaPromise) {
    schemaPromise = (async () => {
      await activePool.query(`
        CREATE TABLE IF NOT EXISTS wcs_book_call_leads (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          phone TEXT,
          notes TEXT,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `);

      await activePool.query(`
        ALTER TABLE wcs_book_call_leads
        ADD COLUMN IF NOT EXISTS source TEXT,
        ADD COLUMN IF NOT EXISTS submitted_path TEXT,
        ADD COLUMN IF NOT EXISTS ip_address TEXT,
        ADD COLUMN IF NOT EXISTS user_agent TEXT,
        ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
        ADD COLUMN IF NOT EXISTS notification_status TEXT NOT NULL DEFAULT 'pending',
        ADD COLUMN IF NOT EXISTS notification_error TEXT,
        ADD COLUMN IF NOT EXISTS notification_sent_at TIMESTAMPTZ;
      `);

      await activePool.query(`
        UPDATE wcs_book_call_leads
        SET source = COALESCE(source, 'vercel-web-api'),
            metadata = COALESCE(metadata, '{}'::jsonb),
            notification_status = COALESCE(notification_status, 'pending')
        WHERE source IS NULL
           OR metadata IS NULL
           OR notification_status IS NULL;
      `);

      await activePool.query(`
        ALTER TABLE wcs_book_call_leads
        ALTER COLUMN source SET NOT NULL,
        ALTER COLUMN metadata SET NOT NULL,
        ALTER COLUMN notification_status SET NOT NULL;
      `);

      await activePool.query(`
        CREATE INDEX IF NOT EXISTS idx_wcs_book_call_leads_created_at
        ON wcs_book_call_leads (created_at DESC);
      `);
    })();
  }

  await schemaPromise;
  return true;
}

function createTransporter() {
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    return null;
  }

  return nodemailer.createTransport({
    host: process.env.SMTP_HOST ?? 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT ?? 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });
}

function getNotificationRecipient() {
  return process.env.ENQUIRY_NOTIFICATION_TO || DEFAULT_ENQUIRY_RECIPIENT;
}

function formatNotificationText(lead) {
  return [
    `Name: ${lead.name}`,
    `Email: ${lead.email}`,
    `Phone: ${lead.phone || '—'}`,
    `Source: ${lead.source}`,
    `Path: ${lead.submittedPath || '—'}`,
    `Submitted: ${lead.createdAt}`,
    '',
    'Message:',
    lead.notes || '(no message provided)'
  ].join('\n');
}

function formatNotificationHtml(lead) {
  const rows = [
    ['Name', lead.name],
    ['Email', lead.email],
    ['Phone', lead.phone || '—'],
    ['Source', lead.source],
    ['Path', lead.submittedPath || '—'],
    ['Submitted', lead.createdAt]
  ]
    .map(([label, value]) => `<tr><td style="padding:8px 12px;font-weight:600;vertical-align:top;">${label}</td><td style="padding:8px 12px;">${value}</td></tr>`)
    .join('');

  const message = lead.notes || '(no message provided)';

  return [
    '<div style="font-family:Arial,sans-serif;color:#0f172a;">',
    `<h2 style="margin-bottom:16px;">${DEFAULT_EMAIL_SUBJECT_PREFIX}</h2>`,
    '<table style="border-collapse:collapse;background:#f8fafc;border:1px solid #e2e8f0;">',
    rows,
    '</table>',
    '<h3 style="margin-top:24px;">Message</h3>',
    `<p style="white-space:pre-wrap;line-height:1.6;">${message}</p>`,
    '</div>'
  ].join('');
}

async function persistLead(lead) {
  const activePool = getPool();
  if (!activePool) {
    return { persisted: false, reason: 'database_not_configured' };
  }

  await ensureSchema();

  await activePool.query(
    `
      INSERT INTO wcs_book_call_leads (
        id,
        name,
        email,
        phone,
        notes,
        source,
        submitted_path,
        ip_address,
        user_agent,
        metadata,
        notification_status,
        created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, $11, $12)
    `,
    [
      lead.id,
      lead.name,
      lead.email,
      lead.phone || null,
      lead.notes || null,
      lead.source,
      lead.submittedPath || null,
      lead.ipAddress || null,
      lead.userAgent || null,
      JSON.stringify(lead.metadata || {}),
      'pending',
      lead.createdAt
    ]
  );

  return { persisted: true };
}

async function updateNotificationStatus(leadId, status, errorMessage) {
  const activePool = getPool();
  if (!activePool) {
    return;
  }

  await ensureSchema();

  await activePool.query(
    `
      UPDATE wcs_book_call_leads
      SET notification_status = $2,
          notification_error = $3,
          notification_sent_at = CASE WHEN $2 = 'sent' THEN NOW() ELSE notification_sent_at END
      WHERE id = $1
    `,
    [leadId, status, errorMessage || null]
  );
}

async function sendNotification(lead) {
  const transporter = createTransporter();
  if (!transporter) {
    return { emailed: false, reason: 'smtp_not_configured' };
  }

  const recipient = getNotificationRecipient();
  const from = process.env.ENQUIRY_NOTIFICATION_FROM || `"World Class Scholars Enquiries" <${process.env.SMTP_USER}>`;
  const subjectPrefix = process.env.ENQUIRY_NOTIFICATION_SUBJECT_PREFIX || DEFAULT_EMAIL_SUBJECT_PREFIX;

  await transporter.sendMail({
    from,
    to: recipient,
    replyTo: lead.email,
    subject: `${subjectPrefix}: ${lead.name}`,
    text: formatNotificationText(lead),
    html: formatNotificationHtml(lead)
  });

  return { emailed: true, recipient };
}

async function recordBookCallLead(lead) {
  const storage = await persistLead(lead);
  const email = await sendNotification(lead).catch(error => ({
    emailed: false,
    reason: 'smtp_send_failed',
    error
  }));

  if (storage.persisted) {
    if (email.emailed) {
      await updateNotificationStatus(lead.id, 'sent');
    } else {
      await updateNotificationStatus(lead.id, email.reason === 'smtp_not_configured' ? 'skipped' : 'failed', email.error ? String(email.error.message || email.error) : null);
    }
  }

  return {
    storage,
    email
  };
}

module.exports = {
  DEFAULT_ENQUIRY_RECIPIENT,
  recordBookCallLead
};