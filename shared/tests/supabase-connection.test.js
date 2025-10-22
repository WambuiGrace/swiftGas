import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';
import test from 'node:test';
import assert from 'node:assert';
import { createClient } from '@supabase/supabase-js';

// Resolve repo-root env file
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envFile = process.env.NODE_ENV === 'production' ? '.env.production' : '.env.development';
const envPath = path.resolve(__dirname, '../../', envFile);
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
}

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

// Helper function to test table access
async function testTableAccess(tableName, primaryKey = 'id') {
  const supabase = makeClient();
  const { error, count, status } = await supabase
    .from(tableName)
    .select(primaryKey, { count: 'exact' })
    .limit(1);

  assert.strictEqual(error, null, `${tableName} error: ${error?.message}`);
  assert.ok([200, 206].includes(status), `${tableName}: unexpected status ${status}`);
  assert.ok(typeof count === 'number' && count >= 0, `${tableName}: count should be a number`);
}

// Test all tables in order of migration
test('Can reach PostgREST and list users table (count-only)', async () => {
  await testTableAccess('users', 'user_id');
});

test('Can reach PostgREST and list orders table (count-only)', async () => {
  await testTableAccess('orders', 'order_id');
});

test('Can reach PostgREST and list suppliers table (count-only)', async () => {
  await testTableAccess('suppliers', 'supplier_id');
});

test('Can reach PostgREST and list gas_types table (count-only)', async () => {
  await testTableAccess('gas_types', 'code');
});

test('Can reach PostgREST and list drivers table (count-only)', async () => {
  await testTableAccess('drivers', 'driver_id');
});

test('Can reach PostgREST and list cylinder_prices table (count-only)', async () => {
  await testTableAccess('cylinder_prices', 'price_id');
});

test('Can reach PostgREST and list cylinder_types table (count-only)', async () => {
  await testTableAccess('cylinder_types', 'cylinder_id');
});

// Migration 008 - energy_metrics (NOT energy_esg)
test('Can reach PostgREST and list energy_metrics table (count-only)', async () => {
  await testTableAccess('energy_metrics', 'metric_id');
});

test('Can reach PostgREST and list loyalty_points table (count-only)', async () => {
  await testTableAccess('loyalty_points', 'points_id');
});

// Migration 010 - transactions
test('Can reach PostgREST and list transactions table (count-only)', async () => {
  await testTableAccess('transactions', 'transaction_id');
});

// Migration 011 - safety_tips
test('Can reach PostgREST and list safety_tips table (count-only)', async () => {
  await testTableAccess('safety_tips', 'tip_id');
});

test('Can reach PostgREST and list notifications table (count-only)', async () => {
  await testTableAccess('notifications', 'notification_id');
});

// Migration 013 - inventory_transactions (primary key is transaction_id)
test('Can reach PostgREST and list inventory_transactions table (count-only)', async () => {
  await testTableAccess('inventory_transactions', 'transaction_id');
});

test('Can reach PostgREST and list driver_earnings table (count-only)', async () => {
  await testTableAccess('driver_earnings', 'earning_id');
});

test('Can reach PostgREST and list customer_support_tickets table (count-only)', async () => {
  await testTableAccess('customer_support_tickets', 'ticket_id');
});

test('Can reach PostgREST and list support_agents table (count-only)', async () => {
  await testTableAccess('support_agents', 'agent_id');
});

// Migration 017 - reviews
test('Can reach PostgREST and list reviews table (count-only)', async () => {
  await testTableAccess('reviews', 'review_id');
});

test('Can reach PostgREST and list system_settings table (count-only)', async () => {
  await testTableAccess('system_settings', 'setting_id');
});

test('Can reach PostgREST and list audit_logs table (count-only)', async () => {
  await testTableAccess('audit_logs', 'log_id');
});

// Summary test - check all tables exist
test('All expected tables exist in database', async () => {
  const supabase = makeClient();
  
  const expectedTables = [
    'users',                      // 001
    'orders',                     // 002
    'suppliers',                  // 003
    'gas_types',                  // 004
    'drivers',                    // 005
    'cylinder_prices',            // 006
    'cylinder_types',             // 007
    'energy_metrics',             // 008 - Energy/sustainability metrics (NOT energy_esg)
    'loyalty_points',             // 009
    'transactions',               // 010 - Payment transactions
    'safety_tips',                // 011 - Safety tips
    'notifications',              // 012
    'inventory_transactions',     // 013 - Inventory management
    'driver_earnings',            // 014
    'customer_support_tickets',   // 015
    'support_agents',             // 016
    'reviews',                    // 017 - Customer reviews/ratings
    'system_settings',            // 018
    'audit_logs'                  // 019
  ];

  let accessibleCount = 0;
  const missingTables = [];
  
  // Verify we can query each table
  for (const tableName of expectedTables) {
    const { error } = await supabase
      .from(tableName)
      .select('*', { count: 'exact', head: true })
      .limit(0);
    
    if (error) {
      missingTables.push(tableName);
      console.warn(`⚠ Table '${tableName}' is not accessible: ${error.message}`);
    } else {
      accessibleCount++;
    }
  }
  
  console.log(`✓ ${accessibleCount} of ${expectedTables.length} tables are accessible`);
  
  if (missingTables.length > 0) {
    console.log(`Missing tables: ${missingTables.join(', ')}`);
  }
  
  assert.strictEqual(
    accessibleCount,
    expectedTables.length,
    `Expected ${expectedTables.length} tables, but only ${accessibleCount} are accessible. Missing: ${missingTables.join(', ')}`
  );
});