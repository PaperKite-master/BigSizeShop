const supabaseConfig = {
  url: process.env.SUPABASE_URL || '',
  anonKey: process.env.SUPABASE_ANON_KEY || '',
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  databaseUrl: process.env.SUPABASE_DB_URL || process.env.DATABASE_URL || '',
  get isConfigured() {
    return Boolean(this.url && this.anonKey);
  },
};

module.exports = { supabaseConfig };