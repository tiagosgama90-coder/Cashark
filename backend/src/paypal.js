require('dotenv').config();

const PAYPAL_API =
  process.env.PAYPAL_MODE === 'live'
    ? 'https://api-m.paypal.com'
    : 'https://api-m.sandbox.paypal.com';

async function getAccessToken() {
  const clientId = process.env.PAYPAL_CLIENT_ID;
  const secret = process.env.PAYPAL_CLIENT_SECRET;
  if (!clientId || !secret) {
    throw new Error('PAYPAL_CREDENTIALS_MISSING');
  }

  const auth = Buffer.from(`${clientId}:${secret}`).toString('base64');
  const res = await fetch(`${PAYPAL_API}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(`PAYPAL_AUTH_FAILED: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

/**
 * Sends EUR to a PayPal email via Payouts API.
 * Docs: https://developer.paypal.com/docs/api/payments.payouts-batch/v1/
 */
async function sendPaypalPayout({ email, amountEuro, cashoutId, note }) {
  const token = await getAccessToken();
  const senderBatchId = `cashark_${cashoutId}`.slice(0, 50);

  const body = {
    sender_batch_header: {
      sender_batch_id: senderBatchId,
      email_subject: 'Cashark payout',
      email_message: note || 'Your Cashark cashout has been sent.',
    },
    items: [
      {
        recipient_type: 'EMAIL',
        amount: {
          value: Number(amountEuro).toFixed(2),
          currency: 'EUR',
        },
        receiver: email,
        note: note || 'Cashark cashout',
        sender_item_id: cashoutId.slice(0, 50),
      },
    ],
  };

  const res = await fetch(`${PAYPAL_API}/v1/payments/payouts`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  const data = await res.json();
  if (!res.ok) {
    const err = new Error(`PAYPAL_PAYOUT_FAILED: ${JSON.stringify(data)}`);
    err.details = data;
    throw err;
  }

  return {
    batchId: data.batch_header?.payout_batch_id || senderBatchId,
    status: data.batch_header?.batch_status || 'PENDING',
    raw: data,
  };
}

function paypalConfigured() {
  return Boolean(process.env.PAYPAL_CLIENT_ID && process.env.PAYPAL_CLIENT_SECRET);
}

module.exports = {
  sendPaypalPayout,
  paypalConfigured,
  PAYPAL_API,
};
