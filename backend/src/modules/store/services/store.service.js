const { AppError } = require('../../../common/errors/app-error');
const storeRepository = require('../repositories/store.repository');

async function getAllStores() {
  return storeRepository.findAll();
}

async function getStoreById(id) {
  const store = await storeRepository.findById(id);
  if (!store) {
    throw new AppError('Store not found', 404);
  }
  return store;
}

module.exports = { getAllStores, getStoreById };
