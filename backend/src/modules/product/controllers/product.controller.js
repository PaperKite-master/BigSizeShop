const { asyncHandler } = require('../../../common/utils/async-handler');
const productService = require('../services/product.service');

const list = asyncHandler(async (req, res) => {
  const result = await productService.list(req.query);

  res.json({
    message: 'Products fetched',
    data: result.items,
    meta: {
      total: result.total,
      page: result.page,
      limit: result.limit,
      totalPages: result.totalPages,
    },
  });
});

const search = asyncHandler(async (req, res) => {
  const result = await productService.search(req.query);

  res.json({
    message: 'Products search results',
    data: result.items,
    meta: {
      total: result.total,
      page: result.page,
      limit: result.limit,
      totalPages: result.totalPages,
    },
  });
});

const filter = asyncHandler(async (req, res) => {
  const result = await productService.filter(req.query);

  res.json({
    message: 'Products filtered',
    data: result.items,
    meta: {
      total: result.total,
      page: result.page,
      limit: result.limit,
      totalPages: result.totalPages,
    },
  });
});

const getById = asyncHandler(async (req, res) => {
  const product = await productService.getById(req.params.id);

  res.json({
    message: 'Product fetched',
    data: product,
  });
});

const create = asyncHandler(async (req, res) => {
  const product = await productService.create(req.body);

  res.status(201).json({
    message: 'Product created',
    data: product,
  });
});

const update = asyncHandler(async (req, res) => {
  const product = await productService.update(req.params.id, req.body);

  res.json({
    message: 'Product updated',
    data: product,
  });
});

const remove = asyncHandler(async (req, res) => {
  await productService.remove(req.params.id);

  res.json({
    message: 'Product deleted',
  });
});

module.exports = {
  list,
  search,
  filter,
  getById,
  create,
  update,
  remove,
};
