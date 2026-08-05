require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const store = require('./store');
const { sendPaypalPayout, paypalConfigured } = require('./paypal');
const {
  stripeConfigured,
  createShopCheckout,
  constructWebhookEvent,
  retrieveSession,
} = require('./stripe');

const app = express();
const PORT = Number(process.env.PORT || 8787);
const ADMIN_KEY = process.env.ADMIN_KEY || 'change-me-admin-key';
const AUTO_PAY_PAYPAL = process.env.AUTO_PAY_PAYPAL !== 'false';
const PUBLIC_APP_URL = process.env.PUBLIC_APP_URL || 'https://cashark.app';
const API_PUBLIC_URL = process.env.API_PUBLIC_URL || `http://127.0.0.1:${PORT}`;

app.use(cors());

function requireAdmin(req, res, next) {
  const key = req.header('x-admin-key');
  if (!key || key !== ADMIN_KEY) {
    return res.status(401).json({ error: 'UNAUTHORIZED' });
  }
  return next();
}

// ── Stripe webhook MUST use raw body (before express.json) ─────────────
app.post(
  '/v1/webhooks/stripe',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    try {
      const sig = req.headers['stripe-signature'];
      let event;
      try {
        event = await constructWebhookEvent(req.body, sig);
      } catch (err) {
        // Dev fallback: if webhook secret missing, accept JSON parse for local tests only
        if (!process.env.STRIPE_WEBHOOK_SECRET && process.env.STRIPE_DEV_INSECURE_WEBHOOK === 'true') {
          event = JSON.parse(req.body.toString('utf8'));
        } else {
          return res.status(400).send(`Webhook Error: ${err.message}`);
        }
      }

      if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        const sessionId = session.id;
        const email = (
          session.metadata?.cashark_user ||
          session.customer_email ||
          session.client_reference_id ||
          ''
        )
          .toString()
          .toLowerCase();
        const itemId = session.metadata?.cashark_item || 'unknown';

        let purchase = store.getPurchase(sessionId);
        if (!purchase) {
          purchase = {
            id: sessionId,
            userEmail: email,
            itemId,
            amountEuro: (session.amount_total || 0) / 100,
            status: 'paid',
            createdAt: new Date().toISOString(),
            paidAt: new Date().toISOString(),
            stripeSessionId: sessionId,
            claimed: false,
          };
        } else {
          purchase = {
            ...purchase,
            status: 'paid',
            paidAt: new Date().toISOString(),
            claimed: purchase.claimed || false,
          };
        }
        store.upsertPurchase(purchase);
      }

      return res.json({ received: true });
    } catch (e) {
      return res.status(500).json({ error: String(e.message || e) });
    }
  },
);

// JSON for the rest of the API
app.use(express.json({ limit: '256kb' }));

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'cashark-payments',
    stripeConfigured: stripeConfigured(),
    paypalConfigured: paypalConfigured(),
    paypalMode: process.env.PAYPAL_MODE || 'sandbox',
    autoPayPaypal: AUTO_PAY_PAYPAL,
    // Clear split: Stripe = YOU receive (shop). PayPal = YOU pay users (cashout).
    flows: {
      receiveMoney: 'stripe_checkout_shop',
      payUsers: 'paypal_payouts_and_manual_queue',
    },
  });
});

/**
 * Create Stripe Checkout for a shop item — money lands in YOUR Stripe balance.
 */
app.post('/v1/checkout', async (req, res) => {
  try {
    if (!stripeConfigured()) {
      return res.status(503).json({
        error: 'STRIPE_NOT_CONFIGURED',
        hint: 'Set STRIPE_SECRET_KEY in backend/.env (same account as your other project is OK).',
      });
    }
    const userEmail = String(req.body.userEmail || '').trim().toLowerCase();
    const itemId = String(req.body.itemId || '').trim();
    const itemTitle = String(req.body.itemTitle || itemId).trim();
    const amountEuro = Number(req.body.amountEuro);
    if (!userEmail || !itemId || !(amountEuro > 0)) {
      return res.status(400).json({ error: 'INVALID_REQUEST' });
    }

    const successUrl =
      String(req.body.successUrl || `${PUBLIC_APP_URL}/stripe-success?session_id={CHECKOUT_SESSION_ID}`);
    const cancelUrl = String(req.body.cancelUrl || `${PUBLIC_APP_URL}/stripe-cancel`);

    const { sessionId, url } = await createShopCheckout({
      userEmail,
      itemId,
      itemTitle,
      amountEuro,
      successUrl,
      cancelUrl,
    });

    store.upsertPurchase({
      id: sessionId,
      userEmail,
      itemId,
      itemTitle,
      amountEuro: Number(amountEuro.toFixed(2)),
      status: 'pending',
      createdAt: new Date().toISOString(),
      paidAt: null,
      stripeSessionId: sessionId,
      claimed: false,
    });

    return res.status(201).json({ sessionId, url });
  } catch (e) {
    return res.status(500).json({ error: 'CHECKOUT_FAILED', detail: String(e.message || e) });
  }
});

/**
 * App polls after returning from Checkout — claim paid items once.
 */
app.post('/v1/checkout/claim', async (req, res) => {
  try {
    const sessionId = String(req.body.sessionId || '').trim();
    const userEmail = String(req.body.userEmail || '').trim().toLowerCase();
    if (!sessionId || !userEmail) {
      return res.status(400).json({ error: 'INVALID_REQUEST' });
    }

    let purchase = store.getPurchase(sessionId);

    // Confirm with Stripe if still pending
    if ((!purchase || purchase.status !== 'paid') && stripeConfigured()) {
      const session = await retrieveSession(sessionId);
      if (session.payment_status === 'paid') {
        const email = (
          session.metadata?.cashark_user ||
          session.customer_email ||
          userEmail
        )
          .toString()
          .toLowerCase();
        purchase = store.upsertPurchase({
          id: sessionId,
          userEmail: email,
          itemId: session.metadata?.cashark_item || purchase?.itemId || 'unknown',
          itemTitle: purchase?.itemTitle || null,
          amountEuro: (session.amount_total || 0) / 100,
          status: 'paid',
          createdAt: purchase?.createdAt || new Date().toISOString(),
          paidAt: new Date().toISOString(),
          stripeSessionId: sessionId,
          claimed: purchase?.claimed || false,
        });
      }
    }

    if (!purchase) return res.status(404).json({ error: 'NOT_FOUND' });
    if (purchase.userEmail !== userEmail) return res.status(403).json({ error: 'FORBIDDEN' });
    if (purchase.status !== 'paid') {
      return res.status(402).json({ error: 'NOT_PAID', status: purchase.status });
    }
    if (purchase.claimed) {
      return res.json({ purchase, alreadyClaimed: true });
    }

    purchase = store.upsertPurchase({ ...purchase, claimed: true, claimedAt: new Date().toISOString() });
    return res.json({
      purchase,
      alreadyClaimed: false,
      grant: { itemId: purchase.itemId },
    });
  } catch (e) {
    return res.status(500).json({ error: 'CLAIM_FAILED', detail: String(e.message || e) });
  }
});

app.get('/v1/purchases/pending', (req, res) => {
  const email = String(req.query.email || '').toLowerCase();
  if (!email) return res.status(400).json({ error: 'EMAIL_REQUIRED' });
  const pending = store
    .listPurchases({ email })
    .filter((p) => p.status === 'paid' && !p.claimed);
  res.json({ purchases: pending });
});

// ── Cashouts (you PAY users — PayPal) ──────────────────────────────────

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

app.get('/v1/admin/purchases', requireAdmin, (_req, res) => {
  res.json({ purchases: store.listPurchases() });
});

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(
    `Cashark payments :${PORT} stripe=${stripeConfigured()} paypal=${paypalConfigured()} api=${API_PUBLIC_URL}`,
  );
});
