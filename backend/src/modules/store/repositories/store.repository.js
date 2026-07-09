const { prisma } = require('../../../common/config/prisma');

async function findAll() {
  return prisma.store_locations.findMany({
    where: { is_active: true },
    orderBy: { created_at: 'asc' },
  });
}

async function findById(id) {
  return prisma.store_locations.findUnique({
    where: { id },
  });
}

module.exports = { findAll, findById };
