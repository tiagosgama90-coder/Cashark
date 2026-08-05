const fs = require('fs');
const path = require('path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');
const CASHOUTS = path.join(DATA_DIR, 'cashouts.json');
const PURCHASES = path.join(DATA_DIR, 'purchases.json');

function ensure() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(CASHOUTS)) fs.writeFileSync(CASHOUTS, JSON.stringify({ cashouts: [] }, null, 2));
  if (!fs.existsSync(PURCHASES)) fs.writeFileSync(PURCHASES, JSON.stringify({ purchases: [] }, null, 2));
}

function readCashouts() {
  ensure();
  return JSON.parse(fs.readFileSync(CASHOUTS, 'utf8'));
}

function writeCashouts(data) {
  ensure();
  fs.writeFileSync(CASHOUTS, JSON.stringify(data, null, 2));
}

function readPurchases() {
  ensure();
  return JSON.parse(fs.readFileSync(PURCHASES, 'utf8'));
}

function writePurchases(data) {
  ensure();
  fs.writeFileSync(PURCHASES, JSON.stringify(data, null, 2));
}

function list({ email } = {}) {
  const data = readCashouts();
  let items = data.cashouts || [];
  if (email) {
    items = items.filter((c) => (c.userEmail || '').toLowerCase() === email.toLowerCase());
  }
  return items.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
}

function get(id) {
  return list().find((c) => c.id === id) || null;
}

function upsert(cashout) {
  const data = readCashouts();
  const idx = data.cashouts.findIndex((c) => c.id === cashout.id);
  if (idx >= 0) data.cashouts[idx] = cashout;
  else data.cashouts.unshift(cashout);
  writeCashouts(data);
  return cashout;
}

function upsertPurchase(purchase) {
  const data = readPurchases();
  const idx = data.purchases.findIndex((p) => p.id === purchase.id);
  if (idx >= 0) data.purchases[idx] = purchase;
  else data.purchases.unshift(purchase);
  writePurchases(data);
  return purchase;
}

function getPurchase(id) {
  ensure();
  return readPurchases().purchases.find((p) => p.id === id) || null;
}

function listPurchases({ email, status } = {}) {
  let items = readPurchases().purchases || [];
  if (email) {
    items = items.filter((p) => (p.userEmail || '').toLowerCase() === email.toLowerCase());
  }
  if (status) {
    items = items.filter((p) => p.status === status);
  }
  return items.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
}

module.exports = {
  list,
  get,
  upsert,
  upsertPurchase,
  getPurchase,
  listPurchases,
  FILE: CASHOUTS,
};
