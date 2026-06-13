const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function parseNumber(value) {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function listProductsQueryDto(query = {}) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 10));

  return {
    page,
    limit,
    search: String(query.search || query.q || '').trim() || undefined,
    category: String(query.category || '').trim() || undefined,
    minPrice: parseNumber(query.minPrice),
    maxPrice: parseNumber(query.maxPrice),
  };
}

function createProductDto(payload = {}) {
  return {
    categoryId: payload.categoryId || null,
    name: String(payload.name || '').trim(),
    description: payload.description ? String(payload.description).trim() : null,
    price: parseNumber(payload.price),
    stock: parseInt(payload.stock, 10) || 0,
    imageUrl: payload.imageUrl ? String(payload.imageUrl).trim() : null,
    is_active: payload.is_active !== undefined ? Boolean(payload.is_active) : true,
    images: Array.isArray(payload.images)
      ? payload.images.map((img) => ({
          image_url: String(img.image_url || img.imageUrl || '').trim(),
          is_thumbnail: Boolean(img.is_thumbnail ?? img.isThumbnail),
        }))
      : [],
    variants: Array.isArray(payload.variants)
      ? payload.variants.map((variant) => ({
          variant_name: String(variant.variant_name || variant.variantName || '').trim(),
          sku: variant.sku ? String(variant.sku).trim() : null,
          price: parseNumber(variant.price),
          stock: parseInt(variant.stock, 10) || 0,
          image_url: variant.image_url || variant.imageUrl
            ? String(variant.image_url || variant.imageUrl).trim()
            : null,
        }))
      : [],
  };
}

function updateProductDto(payload = {}) {
  const data = {};

  if (payload.categoryId !== undefined) {
    data.categoryId = payload.categoryId || null;
  }
  if (payload.name !== undefined) {
    data.name = String(payload.name).trim();
  }
  if (payload.description !== undefined) {
    data.description = payload.description ? String(payload.description).trim() : null;
  }
  if (payload.price !== undefined) {
    data.price = parseNumber(payload.price);
  }
  if (payload.stock !== undefined) {
    data.stock = parseInt(payload.stock, 10) || 0;
  }
  if (payload.imageUrl !== undefined) {
    data.imageUrl = payload.imageUrl ? String(payload.imageUrl).trim() : null;
  }
  if (payload.is_active !== undefined) {
    data.is_active = Boolean(payload.is_active);
  }

  return data;
}

function isUuid(value) {
  return UUID_REGEX.test(value);
}

module.exports = {
  listProductsQueryDto,
  createProductDto,
  updateProductDto,
  isUuid,
};
