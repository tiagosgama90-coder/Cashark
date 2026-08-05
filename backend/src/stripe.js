const Stripe = require('stripe');

function getStripe() {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) return null;
  return new Stripe(key);
}

function stripeConfigured() {
  return Boolean(process.env.STRIPE_SECRET_KEY);
}

/**
 * Create a Checkout Session — money goes to YOUR Stripe account.
 * Same Stripe account as other projects is fine; Cashark just creates sessions
 * with price_data (no need to duplicate Products unless you want).
 */
async function createShopCheckout({
  userEmail,
  itemId,
  itemTitle,
  amountEuro,
  successUrl,
  cancelUrl,
}) {
  const stripe = getStripe();
  if (!stripe) throw new Error('STRIPE_NOT_CONFIGURED');

  const cents = Math.round(Number(amountEuro) * 100);
  if (!(cents >= 50)) throw new Error('AMOUNT_TOO_SMALL'); // Stripe min ~€0.50

  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    customer_email: userEmail,
    client_reference_id: userEmail,
    success_url: successUrl,
    cancel_url: cancelUrl,
    line_items: [
      {
        quantity: 1,
        price_data: {
          currency: 'eur',
          unit_amount: cents,
          product_data: {
            name: `Cashark — ${itemTitle}`,
            description: `Shop item: ${itemId}`,
            metadata: { cashark_item: itemId },
          },
        },
      },
    ],
    metadata: {
      cashark_user: userEmail,
      cashark_item: itemId,
      source: 'cashark_shop',
    },
    payment_intent_data: {
      metadata: {
        cashark_user: userEmail,
        cashark_item: itemId,
      },
    },
  });

  return {
    sessionId: session.id,
    url: session.url,
  };
}

async function constructWebhookEvent(rawBody, signature) {
  const stripe = getStripe();
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!stripe || !secret) throw new Error('STRIPE_WEBHOOK_NOT_CONFIGURED');
  return stripe.webhooks.constructEvent(rawBody, signature, secret);
}

async function retrieveSession(sessionId) {
  const stripe = getStripe();
  if (!stripe) throw new Error('STRIPE_NOT_CONFIGURED');
  return stripe.checkout.sessions.retrieve(sessionId);
}

module.exports = {
  getStripe,
  stripeConfigured,
  createShopCheckout,
  constructWebhookEvent,
  retrieveSession,
};
