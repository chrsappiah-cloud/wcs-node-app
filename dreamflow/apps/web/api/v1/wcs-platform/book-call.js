const { recordBookCallLead } = require('../../_lib/book-call-service');

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function getFirstHeaderValue(value) {
  if (Array.isArray(value)) {
    return value[0];
  }

  return value;
}

function getRequestBody(req) {
  if (!req.body) {
    return {};
  }

  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch {
      return {};
    }
  }

  return req.body;
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ message: 'Method Not Allowed' });
  }

  const body = getRequestBody(req);
  const name = String(body.name || '').trim();
  const email = String(body.email || '').trim();
  const phone = String(body.phone || '').trim();
  const notes = String(body.notes || '').trim();

  if (name.length < 2 || name.length > 80) {
    return res.status(400).json({ message: 'Name must be 2-80 characters' });
  }

  if (!isValidEmail(email)) {
    return res.status(400).json({ message: 'Email is invalid' });
  }

  if (phone.length > 24) {
    return res.status(400).json({ message: 'Phone must be 24 characters or fewer' });
  }

  if (notes.length > 600) {
    return res.status(400).json({ message: 'Notes must be 600 characters or fewer' });
  }

  const forwardedFor = getFirstHeaderValue(req.headers['x-forwarded-for']);
  const userAgent = getFirstHeaderValue(req.headers['user-agent']);
  const origin = getFirstHeaderValue(req.headers.origin);
  const referer = getFirstHeaderValue(req.headers.referer);

  const lead = {
    id: `lead_${Date.now()}`,
    name,
    email,
    phone: phone || undefined,
    notes: notes || undefined,
    createdAt: new Date().toISOString(),
    source: 'vercel-web-api',
    submittedPath: String(body.path || referer || origin || '').trim() || undefined,
    ipAddress: forwardedFor ? forwardedFor.split(',')[0].trim() : undefined,
    userAgent: userAgent || undefined,
    metadata: {
      origin: origin || undefined,
      referer: referer || undefined
    }
  };

  const delivery = await recordBookCallLead(lead);

  console.log('Book call lead received', {
    id: lead.id,
    storage: delivery.storage,
    email: delivery.email
  });

  return res.status(201).json({
    message: 'Enquiry received. We will be in touch shortly.',
    lead,
    delivery: {
      persisted: delivery.storage.persisted,
      notificationSent: delivery.email.emailed,
      storageReason: delivery.storage.reason,
      emailReason: delivery.email.reason
    }
  });
};
