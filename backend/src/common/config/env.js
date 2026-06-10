const requiredEnv = ['JWT_SECRET'];

function validateEnv(env = process.env) {
  const missing = requiredEnv.filter((key) => !env[key]);

  if (!env.SUPABASE_DB_URL && !env.DATABASE_URL) {
    missing.push('SUPABASE_DB_URL or DATABASE_URL');
  }

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

module.exports = { validateEnv };