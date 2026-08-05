const fs = require('fs');
const path = require('path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');
const FILE = path.join(DATA_DIR, 'cashouts.json');

function ensure() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(FILE)) fs.writeFileSync(FILE, JSON.stringify({ cashouts: [] }, null, 2));
}

function readAll() {
  ensure();
  return JSON.parse(fs.readFileSync(FILE, 'utf8'));
}

function writeAll(data) {
  ensure();
  fs.writeFileSync(FILE, JSON.stringify(data, null, 2));
}

function list({ email } = {}) {
  const data = readAll();
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
  const data = readAll();
  const idx = data.cashouts.findIndex((c) => c.id === cashout.id);
  if (idx >= 0) data.cashouts[idx] = cashout;
  else data.cashouts.unshift(cashout);
  writeAll(data);
  return cashout;
}

module.exports = { list, get, upsert, FILE };
