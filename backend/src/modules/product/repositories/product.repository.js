const { prisma } = require('../../../common/config/prisma');
const { isUuid } = require('../dto/product.dto');

const PRODUCT_INCLUDE = {
  categories: true,
  product_images: true,
  product_variants: true,
};

function buildWhereClause(filters = {}) {
  const where = { is_active: true };

  if (filters.search) {
    where.OR = [
      { name: { contains: filters.search, mode: 'insensitive' } },
      { description: { contains: filters.search, mode: 'insensitive' } },
    ];
  }

  if (filters.category) {
    where.categories = isUuid(filters.category)
      ? { id: filters.category }
      : { name: { equals: filters.category, mode: 'insensitive' } };
  }

  if (filters.minPrice !== undefined || filters.maxPrice !== undefined) {
    where.price = {};

    if (filters.minPrice !== undefined) {
      where.price.gte = filters.minPrice;
    }

    if (filters.maxPrice !== undefined) {
      where.price.lte = filters.maxPrice;
    }
  }

  return where;
}

async function findMany(filters = {}) {
  const { page = 1, limit = 10 } = filters;
  const where = buildWhereClause(filters);
  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    prisma.product.findMany({
      where,
      include: PRODUCT_INCLUDE,
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.product.count({ where }),
  ]);

  return {
    items,
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit) || 0,
  };
}

async function findById(id) {
  return prisma.product.findUnique({
    where: { id },
    include: PRODUCT_INCLUDE,
  });
}

async function create(data, images = [], variants = []) {
  return prisma.product.create({
    data: {
      ...data,
      product_images: images.length
        ? { create: images.filter((img) => img.image_url) }
        : undefined,
      product_variants: variants.length
        ? { create: variants.filter((variant) => variant.variant_name) }
        : undefined,
    },
    include: PRODUCT_INCLUDE,
  });
}

async function update(id, data) {
  return prisma.product.update({
    where: { id },
    data,
    include: PRODUCT_INCLUDE,
  });
}

async function remove(id) {
  return prisma.product.delete({
    where: { id },
  });
}

module.exports = {
  findMany,
  findById,
  create,
  update,
  remove,
};
