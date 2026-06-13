const { asyncHandler } = require('../../../common/utils/async-handler');
const categoryService = require('../services/category.service');

const list = asyncHandler(async (req, res) => {
  const categories = await categoryService.list();

  res.json({
    message: 'Categories fetched',
    data: categories,
  });
});

const create = asyncHandler(async (req, res) => {
  const category = await categoryService.create(req.body);

  res.status(201).json({
    message: 'Category created',
    data: category,
  });
});

const update = asyncHandler(async (req, res) => {
  const category = await categoryService.update(req.params.id, req.body);

  res.json({
    message: 'Category updated',
    data: category,
  });
});

const remove = asyncHandler(async (req, res) => {
  await categoryService.remove(req.params.id);

  res.json({
    message: 'Category deleted',
  });
});

module.exports = {
  list,
  create,
  update,
  remove,
};
