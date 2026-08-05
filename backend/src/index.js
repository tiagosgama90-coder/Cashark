require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const store = require('./store');
const { sendPaypalPayout, paypalConfigured } = require('./paypal');

const app = express();
const PORT = Number(process.env.PORT || 8787);
const ADMIN_KEY = process.env.ADMIN_KEY || 'change-me-admin-key';
const AUTO_PAY_PAYPAL = process.env.AUTO_PAY_PAYPAL !== 'false';

app.use(cors());
app.use(express.json({ limit: '256kb' }));

function requireAdmin(req, res, next) {
  const key = req.header('x-admin-key');
  if (!key || key !== ADMIN_KEY) {
    return res.status(401).json({ error: 'UNAUTHORIZED' });
  }
  return next();
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'cashark-payouts',
    paypalConfigured: paypalConfigured(),
    mode: process.env.PAYPAL_MODE || 'sandbox',
    autoPayPaypal: AUTO_PAY_PAYPAL,
  });
});

/**
 * Create cashout request.
 * PayPal can be auto-processed when credentials exist.
 * Other methods stay pending for admin / provider plugins.
 */
app.post('/v1/cashouts', async (req, res) => {
  try {
    const body = req.body || {};
    const amountEuro = Number(body.amountEuro);
    const method = String(body.method || '');
    const destination = String(body.destination || '').trim();
    const userEmail = String(body.userEmail || '').trim().toLowerCase();

    if (!userEmail || !destination || !method || !(amountEuro >= 10)) {
      return res.status(400).json({ error: 'INVALID_REQUEST', minAmount: 10 });
    }

    let cashout = {
      id: body.id || uuidv4(),
      userEmail,
      amountEuro: Number(amountEuro.toFixed(2)),
      method,
      destination,
      accountName: body.accountName || null,
      status: 'pending',
      createdAt: body.createdAt || new Date().toISOString(),
      providerRef: null,
      note: null,
    };

    // Auto PayPal when configured
    if (method === 'paypal' && AUTO_PAY_PAYPAL && paypalConfigured()) {
      cashout.status = 'processing';
      store.upsert(cashout);
      try {
        const result = await sendPaypalPayout({
          email: destination,
          amountEuro: cashout.amountEuro,
          cashoutId: cashout.id,
          note: `Cashark cashout for ${userEmail}`,
        });
        cashout = {
          ...cashout,
          status: 'paid',
          providerRef: result.batchId,
          note: `paypal_${result.status}`,
        };
      } catch (e) {
        cashout = {
          ...cashout,
          status: 'failed',
          note: String(e.message || e).slice(0, 500),
        };
      }
    } else if (method === 'paypal' && !paypalConfigured()) {
      cashout.note = 'paypal_credentials_missing_queued';
    } else {
      cashout.note = 'manual_or_provider_queue';
    }

    store.upsert(cashout);
    return res.status(201).json({ cashout });
  } catch (e) {
    return res.status(500).json({ error: 'SERVER_ERROR', detail: String(e.message || e) });
  }
});

app.get('/v1/cashouts', (req, res) => {
  const email = req.query.email ? String(req.query.email) : undefined;
  res.json({ cashouts: store.list({ email }) });
});

app.get('/v1/cashouts/:id', (req, res) => {
  const item = store.get(req.params.id);
  if (!item) return res.status(404).json({ error: 'NOT_FOUND' });
  return res.json({ cashout: item });
});

/** Admin: process a pending cashout (PayPal only for now). */
app.post('/v1/admin/cashouts/:id/pay', requireAdmin, async (req, res) => {
  const item = store.get(req.params.id);
  if (!item) return res.status(404).json({ error: 'NOT_FOUND' });
  if (!['pending', 'failed'].includes(item.status)) {
    return res.status(400).json({ error: 'INVALID_STATUS', status: item.status });
  }
  if (item.method !== 'paypal') {
    return res.status(400).json({
      error: 'METHOD_NOT_AUTOMATED',
      hint: 'Mark as paid manually after sending via Skrill/Revolut/bank/USDT.',
    });
  }
  if (!paypalConfigured()) {
    return res.status(400).json({ error: 'PAYPAL_CREDENTIALS_MISSING' });
  }

  let cashout = { ...item, status: 'processing' };
  store.upsert(cashout);
  try {
    const result = await sendPaypalPayout({
      email: cashout.destination,
      amountEuro: cashout.amountEuro,
      cashoutId: cashout.id,
      note: `Cashark cashout for ${cashout.userEmail}`,
    });
    cashout = {
      ...cashout,
      status: 'paid',
      providerRef: result.batchId,
      note: `paypal_${result.status}`,
    };
    store.upsert(cashout);
    return res.json({ cashout });
  } catch (e) {
    cashout = { ...cashout, status: 'failed', note: String(e.message || e).slice(0, 500) };
    store.upsert(cashout);
    return res.status(502).json({ error: 'PAYOUT_FAILED', cashout });
  }
});

/** Admin: mark non-PayPal methods paid/rejected after manual transfer. */
app.post('/v1/admin/cashouts/:id/status', requireAdmin, (req, res) => {
  const item = store.get(req.params.id);
  if (!item) return res.status(404).json({ error: 'NOT_FOUND' });
  const status = String(req.body.status || '');
  if (!['paid', 'rejected', 'pending', 'processing', 'failed'].includes(status)) {
    return res.status(400).json({ error: 'INVALID_STATUS' });
  }
  const cashout = {
    ...item,
    status,
    providerRef: req.body.providerRef || item.providerRef,
    note: req.body.note || item.note,
  };
  store.upsert(cashout);
  return res.json({ cashout });
});

app.get('/v1/admin/cashouts', requireAdmin, (_req, res) => {
  res.json({ cashouts: store.list() });
});

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Cashark payouts listening on :${PORT} (paypal=${paypalConfigured()})`);
});
