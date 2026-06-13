const { AppError } = require('../../../common/errors/app-error');
const categoryRepository = require('../repositories/category.repository');
const { createCategoryDto, updateCategoryDto } = require('../dto/category.dto');

async function list() {
  return categoryRepository.findAll();
}

async function create(payload) {
  const data = createCategoryDto(payload);

  if (!data.name) {
    throw new AppError('Category name is required', 400);
  }

  const existing = await categoryRepository.findByName(data.name);

  if (existing) {
    throw new AppError('Category already exists', 409);
  }

  return categoryRepository.create(data);
}

async function update(id, payload) {
  const data = updateCategoryDto(payload);

  if (!Object.keys(data).length) {
    throw new AppError('No fields to update', 400);
  }

  const category = await categoryRepository.findById(id);

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  if (data.name && data.name !== category.name) {
    const existing = await categoryRepository.findByName(data.name);

    if (existing) {
      throw new AppError('Category already exists', 409);
    }
  }

  return categoryRepository.update(id, data);
}

async function remove(id) {
  const category = await categoryRepository.findById(id);

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  return categoryRepository.remove(id);
}

module.exports = {
  list,
  create,
  update,
  remove,
};
