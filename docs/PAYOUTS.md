# Cashark real payouts (PayPal + others)

Backend that pays real money when users cash out virtual **Cash** (after converting Sharks).

## Flow

1. User earns Sharks / Cash in the app  
2. Converts Sharks → Cash (€)  
3. Opens **Perfil → Pedir levantamento**  
4. Chooses method + destination  
5. API locks the request and:
   - **PayPal** → auto-paid via [PayPal Payouts API](https://developer.paypal.com/docs/api/payments.payouts-batch/v1/) when credentials are set  
   - **Skrill / Revolut / Wise / SEPA / USDT** → queued for you (admin marks `paid` after you send)

Minimum cashout: **€10.00** (creator-safe gate — see `CREATOR_ECONOMY.md`)

## Methods included

| Method | Auto-pay | Destination field |
|--------|----------|-------------------|
| PayPal | Yes (API) | PayPal email |
| Skrill | Manual/admin | Skrill email |
| Revolut | Manual/admin | email / phone |
| Wise | Manual/admin | Wise email |
| Bank SEPA | Manual/admin | IBAN |
| USDT TRC20 | Manual/admin | wallet address |

## Setup PayPal (required for automatic money)

1. Create a [PayPal Developer](https://developer.paypal.com/) Business app  
2. Enable **Payouts** on the account (may need PayPal approval)  
3. Copy **Sandbox** Client ID + Secret  
4. Fund the sandbox business account for tests  
5. Copy `.env.example` → `.env` and fill:

```bash
cd backend
cp .env.example .env
# edit PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET, ADMIN_KEY
npm install
npm start
```

API listens on `http://127.0.0.1:8787`

Health check:

```bash
curl http://127.0.0.1:8787/health
```

## App config

By default the Flutter app calls `http://127.0.0.1:8787`.  
For a phone / production build:

```bash
flutter run --dart-define=CASHARK_API_URL=https://YOUR-API-HOST
flutter build apk --dart-define=CASHARK_API_URL=https://YOUR-API-HOST
```

Deploy `backend/` to Railway, Render, Fly.io, VPS, etc. Use HTTPS.

## Admin actions

List all cashouts:

```bash
curl -H "x-admin-key: YOUR_ADMIN_KEY" http://127.0.0.1:8787/v1/admin/cashouts
```

Force-pay a pending PayPal cashout:

```bash
curl -X POST -H "x-admin-key: YOUR_ADMIN_KEY" \
  http://127.0.0.1:8787/v1/admin/cashouts/CASHOUT_ID/pay
```

Mark Skrill/SEPA/USDT as paid after you transfer manually:

```bash
curl -X POST -H "x-admin-key: YOUR_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status":"paid","providerRef":"manual-tx-123"}' \
  http://127.0.0.1:8787/v1/admin/cashouts/CASHOUT_ID/status
```

## Going live checklist

- [ ] PayPal **live** Client ID/Secret + `PAYPAL_MODE=live`  
- [ ] Enough balance in the PayPal business account to cover payouts  
- [ ] Strong `ADMIN_KEY`  
- [ ] HTTPS API URL in the app (`CASHARK_API_URL`)  
- [ ] Fraud checks (unique device, min playtime) — recommended before scale  
- [ ] Privacy Policy updated with payout processors  
- [ ] Comply with local gambling / rewards laws in your markets  

## Optional next providers

Same queue pattern can add:

- Skrill MassPay API  
- Coinbase Commerce / TRON USDT node for crypto  
- Stripe Connect (less common for casual rewards, more for marketplaces)
