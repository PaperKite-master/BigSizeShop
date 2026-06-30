const { AppError } = require('../../../common/errors/app-error');
const { prisma } = require('../../../common/config/prisma');
const productRepository = require('../repositories/product.repository');
const {
  createProductDto,
  listProductsQueryDto,
  updateProductDto,
} = require('../dto/product.dto');

async function list(query) {
  const filters = listProductsQueryDto(query);
  return productRepository.findMany(filters);
}

async function search(query) {
  const filters = listProductsQueryDto({
    ...query,
    search: query.search || query.q,
  });

  if (!filters.search) {
    throw new AppError('Search query is required', 400);
  }

  return productRepository.findMany(filters);
}

async function filter(query) {
  const filters = listProductsQueryDto(query);
  return productRepository.findMany(filters);
}

async function getById(id) {
  const product = await productRepository.findById(id);

  if (!product) {
    throw new AppError('Product not found', 404);
  }

  return product;
}

async function create(payload) {
  const data = createProductDto(payload);

  if (!data.name) {
    throw new AppError('Product name is required', 400);
  }

  if (data.price === undefined || data.price < 0) {
    throw new AppError('Valid product price is required', 400);
  }

  if (data.categoryId) {
    const category = await prisma.category.findUnique({
      where: { id: data.categoryId },
    });

    if (!category) {
      throw new AppError('Category not found', 404);
    }
  }

  const { images, variants, ...productData } = data;
  return productRepository.create(productData, images, variants);
}

async function update(id, payload) {
  const data = updateProductDto(payload);

  if (!Object.keys(data).length) {
    throw new AppError('No fields to update', 400);
  }

  const product = await productRepository.findById(id);

  if (!product) {
    throw new AppError('Product not found', 404);
  }

  if (data.categoryId) {
    const category = await prisma.category.findUnique({
      where: { id: data.categoryId },
    });

    if (!category) {
      throw new AppError('Category not found', 404);
    }
  }

  if (data.price !== undefined && data.price < 0) {
    throw new AppError('Price must be zero or greater', 400);
  }

  return productRepository.update(id, data);
}

async function remove(id) {
  const product = await productRepository.findById(id);

  if (!product) {
    throw new AppError('Product not found', 404);
  }

  return productRepository.remove(id);
}

module.exports = {
  list,
  search,
  filter,
  getById,
  create,
  update,
  remove,
};
