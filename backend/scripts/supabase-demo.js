#!/usr/bin/env node
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
const table = process.argv[2] || process.env.SUPABASE_TEST_TABLE || 'your_table';

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_ANON_KEY in environment.');
  process.exit(1);
}

const base = SUPABASE_URL.replace(/\/$/, '');
const url = `${base}/rest/v1/${encodeURIComponent(table)}?select=*`;

const headers = {
  apikey: SUPABASE_ANON_KEY,
  Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
  Accept: 'application/json',
};

(async () => {
  try {
    // Node 18+ has global fetch. If not available, user can install node-fetch.
    if (typeof fetch !== 'function') {
      console.error('Global fetch is not available. Use Node 18+ or install node-fetch.');
      process.exit(1);
    }

    const res = await fetch(url, { headers });
    if (!res.ok) {
      const text = await res.text();
      console.error('Supabase request failed', res.status, text);
      process.exit(1);
    }

    const data = await res.json();
    console.log(JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Error fetching from Supabase:', err.message || err);
    process.exit(1);
  }
})();
