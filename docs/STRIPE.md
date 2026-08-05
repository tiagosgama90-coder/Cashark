# Stripe on Cashark — receive shop payments

## Can I reuse my other project’s Stripe account?

**Yes.** One Stripe account can power many apps.

- Reuse the same **Secret key** (or create a **Restricted key** limited to Checkout + Webhooks)
- No need to copy Products — Cashark uses Checkout `price_data` inline
- Optional: tag payments with metadata `source=cashark_shop` (already set)
- Create a **separate webhook endpoint** for Cashark: `https://YOUR-API/v1/webhooks/stripe`

## Money flows (keep it simple)

| Direction | Provider | What |
|-----------|----------|------|
| **Players → You** | **Stripe Checkout** | Shop packs (lives, spins, VIP…) |
| **You → Players** | **PayPal Payouts** (+ Skrill/etc queue) | Cashouts ≥ €10 |

You do **not** need Stripe Connect to get paid. Standard Stripe charges are enough.

Activate only what you use:
1. Stripe **Payments / Checkout** (required for shop)
2. PayPal **Payouts** (required only if you auto-pay cashouts)
3. Leave unused methods off

## Setup (5 minutes)

1. Stripe Dashboard → **Developers → API keys** → copy `sk_test_…` (then `sk_live_…`)
2. `cd backend && cp .env.example .env` → paste `STRIPE_SECRET_KEY`
3. Deploy API with HTTPS
4. Stripe → **Webhooks** → Add endpoint  
   `https://YOUR-API/v1/webhooks/stripe`  
   Event: `checkout.session.completed` → copy `whsec_…` into `STRIPE_WEBHOOK_SECRET`
5. Restart API → `/health` should show `"stripeConfigured": true`
6. In the app Shop → purple **Stripe €…** button

## App UX

1. User taps **Stripe €x.xx**
2. Browser opens Stripe Checkout (card / Apple Pay / Google Pay where available)
3. After pay, user returns to app → taps **Claim Stripe purchase** (or Shop auto-claims pending)
4. Item is granted once (idempotent `claimed` flag)

## Local test

```bash
cd backend
npm install
stripe listen --forward-to localhost:8787/v1/webhooks/stripe   # Stripe CLI
# put printed whsec_ into .env
npm start
```

## Galaxy Store note

Samsung may prefer **Galaxy IAP** for pure digital goods inside the APK.  
Stripe is still excellent for:
- web / companion checkout
- funding your payout float
- regions / SKUs you sell outside strict IAP rules  

If Galaxy rejects card links in-app, keep Stripe on a web “Buy packs” page and deep-link back — the same `/v1/checkout` + claim API works.

## Security

- Never put `STRIPE_SECRET_KEY` in the Flutter app — only on the server
- Webhook signature verification is required in production
- `ADMIN_KEY` protects admin purchase/cashout lists
