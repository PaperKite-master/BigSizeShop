const { asyncHandler } = require('../../../common/utils/async-handler');
const storeService = require('../services/store.service');

const getAllStores = asyncHandler(async (req, res) => {
  const stores = await storeService.getAllStores();
  res.json({
    message: 'Store locations fetched successfully',
    data: stores,
  });
});

const getStoreById = asyncHandler(async (req, res) => {
  const store = await storeService.getStoreById(req.params.id);
  res.json({
    message: 'Store location fetched successfully',
    data: store,
  });
});

module.exports = { getAllStores, getStoreById };
