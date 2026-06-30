const { asyncHandler } = require('../../../common/utils/async-handler');
const addressService = require('../services/address.service');

const list = asyncHandler(async (req, res) => {
  const addresses = await addressService.list(req.user.id);
  res.json({
    message: 'Addresses retrieved successfully',
    data: addresses,
  });
});

const create = asyncHandler(async (req, res) => {
  const address = await addressService.create(req.user.id, req.body);
  res.status(201).json({
    message: 'Address created successfully',
    data: address,
  });
});

const update = asyncHandler(async (req, res) => {
  const address = await addressService.update(req.user.id, req.params.id, req.body);
  res.json({
    message: 'Address updated successfully',
    data: address,
  });
});

const remove = asyncHandler(async (req, res) => {
  const result = await addressService.remove(req.user.id, req.params.id);
  res.json({
    message: result.message,
  });
});

module.exports = {
  list,
  create,
  update,
  remove,
};
