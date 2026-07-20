const { asyncHandler } = require('../../../common/utils/async-handler');
const addressService = require('../services/address.service');

const listAddresses = asyncHandler(async (req, res) => {
  const data = await addressService.list(req.user.id);
  res.json({ message: 'Addresses retrieved successfully', data });
});

const createAddress = asyncHandler(async (req, res) => {
  const data = await addressService.create(req.user.id, req.body);
  res.status(201).json({ message: 'Address created successfully', data });
});

const updateAddress = asyncHandler(async (req, res) => {
  const data = await addressService.update(req.user.id, req.params.id, req.body);
  res.json({ message: 'Address updated successfully', data });
});

const deleteAddress = asyncHandler(async (req, res) => {
  await addressService.remove(req.user.id, req.params.id);
  res.json({ message: 'Address deleted successfully' });
});

module.exports = {
  listAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
};
