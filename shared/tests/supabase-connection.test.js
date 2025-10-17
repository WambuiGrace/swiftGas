// Load env from the repo root
const path = require('node:path');
const fs = require('node:fs');
const dotenv = require('dotenv');

const envFile =
  process.env.NODE_ENV === 'production' ? '.env.production' : '.env.development';
const envPath = path.resolve(__dirname, '../../', envFile);
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
}

// Basic assertions and test runner
const test = require('node:test');
const assert = require('node:assert');

// Supabase
const { createClient } = require('@supabase/supabase-js');

// Helper to create client with service role
function makeClient() {
  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  assert.ok(url, 'SUPABASE_URL is missing');
  assert.ok(serviceKey, 'SUPABASE_SERVICE_ROLE_KEY is missing');

  return createClient(url, serviceKey, {
    auth: { persistSession: false }
  });
}

test('Supabase env is configured', () => {
  assert.ok(process.env.SUPABASE_URL, 'SUPABASE_URL must be set');
  assert.ok(process.env.SUPABASE_SERVICE_ROLE_KEY, 'SUPABASE_SERVICE_ROLE_KEY must be set');
});

test('Can reach PostgREST and list users table (count-only)', async () => {
  const supabase = makeClient();
  const { error, count, status } = await supabase
    .from('users')
    .select('user_id', { count: 'exact' })
    .limit(1);

  assert.strictEqual(error, null, `users error: ${error?.message}`);
  // 200 or 206 (Partial Content) when a range/limit is applied
  assert.ok([200, 206].includes(status), `unexpected status ${status}`);
  assert.ok(typeof count === 'number' && count >= 0, 'users count should be a number');
});

test('Can reach PostgREST and list orders table (count-only)', async () => {
  const supabase = makeClient();
  const { error, count, status } = await supabase
    .from('orders')
    .select('order_id', { count: 'exact' })
    .limit(1);

  assert.strictEqual(error, null, `orders error: ${error?.message}`);
  // 200 or 206 (Partial Content) when a range/limit is applied
  assert.ok([200, 206].includes(status), `unexpected status ${status}`);
  assert.ok(typeof count === 'number' && count >= 0, 'orders count should be a number');
});