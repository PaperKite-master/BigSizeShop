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

  const categoryFilters = buildCategoryFilter(filters);
  if (categoryFilters) {
    if (where.OR) {
      where.AND = [{ OR: where.OR }, { OR: categoryFilters }];
      delete where.OR;
    } else {
      where.OR = categoryFilters;
    }
  }

  if (filters.minPrice !== undefined || filters.maxPrice !== undefined) {
    where.price = {};
    if (filters.minPrice !== undefined) where.price.gte = filters.minPrice;
    if (filters.maxPrice !== undefined) where.price.lte = filters.maxPrice;
  }

  if (filters.inStock === true) {
    where.stock = { gt: 0 };
  }

  return where;
}


function buildCategoryFilter(filters) {
  const entries = [];

  if (Array.isArray(filters.categories) && filters.categories.length) {
    for (const c of filters.categories) {
      entries.push(buildSingleCategoryCondition(c));
    }
  } else if (filters.category) {
    entries.push(buildSingleCategoryCondition(filters.category));
  }

  return entries.length ? entries.map((cond) => ({ categories: cond })) : null;
}

function buildSingleCategoryCondition(value) {
  return isUuid(value)
    ? { id: value }
    : { name: { equals: value, mode: 'insensitive' } };
}


function buildOrderBy(filters = {}) {
  const { sortBy = 'createdAt', sortOrder = 'asc' } = filters;

  const field = sortBy === 'rating' ? 'createdAt' : sortBy;
  return { [field]: sortOrder };
}


function buildPaginationResult(items, total, page, limit) {
  return {
    items,
    total,
    page: Number(page),
    limit: Number(limit),
    totalPages: Math.ceil(total / limit) || 0,
  };
}


async function findMany(filters = {}) {
  const { page = 1, limit = 10 } = filters;
  const where = buildWhereClause(filters);
  const orderBy = buildOrderBy(filters);
  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    prisma.product.findMany({
      where,
      include: PRODUCT_INCLUDE,
      orderBy,
      skip,
      take: Number(limit),
    }),
    prisma.product.count({ where }),
  ]);

  return buildPaginationResult(items, total, page, limit);
}


async function findById(id) {
  return prisma.product.findUnique({
    where: { id },
    include: PRODUCT_INCLUDE,
  });
}


async function findManyByFullText(keyword, filters = {}) {
  const { page = 1, limit = 10, minPrice, maxPrice, minRating, maxRating, inStock, sortBy = 'createdAt', sortOrder = 'asc' } = filters;
  const skip = (page - 1) * limit;
  const safeKeyword = keyword.replace(/[\\'"]/g, '');

  const whereClauses = [`p.is_active = true`];
  const params = [];
  let paramIdx = 1;

  whereClauses.push(
    `(
      to_tsvector('simple', coalesce(p.name, '')) ||
      to_tsvector('simple', coalesce(p.description, ''))
    ) @@ plainto_tsquery('simple', $${paramIdx})`
  );
  params.push(safeKeyword);
  paramIdx++;

  if (minPrice !== undefined) {
    whereClauses.push(`p.price >= $${paramIdx}`);
    params.push(minPrice);
    paramIdx++;
  }
  if (maxPrice !== undefined) {
    whereClauses.push(`p.price <= $${paramIdx}`);
    params.push(maxPrice);
    paramIdx++;
  }

  if (inStock === true) {
    whereClauses.push(`p.stock > 0`);
  }

  const categoryConditions = buildRawCategoryConditions(filters, params, paramIdx);
  if (categoryConditions.sql) {
    whereClauses.push(categoryConditions.sql);
    paramIdx = categoryConditions.nextParamIdx;
  }

  const whereSQL = whereClauses.join(' AND ');


  const havingClauses = [];
  if (minRating !== undefined) {
    havingClauses.push(`COALESCE(AVG(rv.rating), 0) >= ${minRating}`);
  }
  if (maxRating !== undefined) {
    havingClauses.push(`COALESCE(AVG(rv.rating), 5) <= ${maxRating}`);
  }
  const havingSQL = havingClauses.length ? `HAVING ${havingClauses.join(' AND ')}` : '';

  const allowedSortCols = {
    name: 'p.name',
    price: 'p.price',
    createdAt: 'p.created_at',
    stock: 'p.stock',
    rating: 'avg_rating',
  };
  const sortCol = allowedSortCols[sortBy] || 'p.created_at';
  const sortDir = sortOrder === 'desc' ? 'DESC' : 'ASC';

  const dataSQL = `
    SELECT
      p.*,
      COALESCE(AVG(rv.rating), NULL)::float AS avg_rating,
      COUNT(*) OVER() AS _full_count
    FROM products p
    LEFT JOIN reviews rv ON rv.product_id = p.id
    WHERE ${whereSQL}
    GROUP BY p.id
    ${havingSQL}
    ORDER BY ${sortCol} ${sortDir} NULLS LAST
    LIMIT $${paramIdx} OFFSET $${paramIdx + 1}
  `;
  params.push(Number(limit), Number(skip));

  const rows = await prisma.$queryRawUnsafe(dataSQL, ...params);

  // Parse _full_count from first row (window function)
  const total = rows.length > 0 ? Number(rows[0]._full_count) : 0;

  // Attach relations by fetching matching product records via ORM
  const ids = rows.map((r) => r.id);
  const ratingMap = Object.fromEntries(rows.map((r) => [r.id, r.avg_rating ?? null]));

  let items = [];
  if (ids.length) {
    const ormRows = await prisma.product.findMany({
      where: { id: { in: ids } },
      include: PRODUCT_INCLUDE,
      orderBy,
    });

    // Preserve raw-query order and attach avg_rating
    const ormMap = Object.fromEntries(ormRows.map((r) => [r.id, r]));
    items = ids
      .filter((id) => ormMap[id])
      .map((id) => ({ ...ormMap[id], avg_rating: ratingMap[id] }));
  }

  return buildPaginationResult(items, total, page, limit);
}

// Helper: build raw SQL category condition + advance paramIdx
function buildRawCategoryConditions(filters, params, paramIdx) {
  const entries = [];

  if (Array.isArray(filters.categories) && filters.categories.length) {
    entries.push(...filters.categories);
  } else if (filters.category) {
    entries.push(filters.category);
  }

  if (!entries.length) return { sql: null, nextParamIdx: paramIdx };

  const uuids = entries.filter(isUuid);
  const names = entries.filter((e) => !isUuid(e));

  const subClauses = [];

  if (uuids.length) {
    // Use ANY for UUID list
    subClauses.push(`cat.id = ANY($${paramIdx}::uuid[])`);
    params.push(uuids);
    paramIdx++;
  }

  if (names.length) {
    for (const name of names) {
      subClauses.push(`lower(cat.name) = lower($${paramIdx})`);
      params.push(name);
      paramIdx++;
    }
  }

  const sql = `EXISTS (
    SELECT 1 FROM categories cat
    WHERE cat.id = p.category_id AND (${subClauses.join(' OR ')})
  )`;

  return { sql, nextParamIdx: paramIdx };
}

// ─── MUTATIONS ─────────────────────────────────────────────────────────────────

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

// ─── EXPORTS ───────────────────────────────────────────────────────────────────

module.exports = {
  findMany,
  findById,
  findManyByFullText,
  create,
  update,
  remove,
};
