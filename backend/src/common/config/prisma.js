const { PrismaClient } = require('@prisma/client');

function getDatabaseUrl() {
  const url = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;

  if (!url) {
    return url;
  }

  if (url.includes('pgbouncer=true')) {
    return url;
  }

  const usesPooler = url.includes('pooler.supabase.com') || url.includes(':6543');

  if (usesPooler) {
    const separator = url.includes('?') ? '&' : '?';
    return `${url}${separator}pgbouncer=true`;
  }

  return url;
}

const prisma =
  globalThis.prisma ||
  new PrismaClient({
    datasources: {
      db: {
        url: getDatabaseUrl(),
      },
    },
  });

if (process.env.NODE_ENV !== 'production') {
  globalThis.prisma = prisma;
}

module.exports = { prisma };
