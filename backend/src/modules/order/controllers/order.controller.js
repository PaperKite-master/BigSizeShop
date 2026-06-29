const { asyncHandler } = require('../../../common/utils/async-handler');
const orderService = require('../services/order.service');

const createOrder = asyncHandler(async (req, res) => {
  const result = await orderService.createOrder(req.user.id, req.body);

  res.status(201).json({
    message: 'Order created successfully',
    data: result,
  });
});

const cancelOrder = asyncHandler(async (req, res) => {
  const result = await orderService.cancelOrder(req.user.id, req.params.id);

  res.json({
    message: 'Order cancelled successfully',
    data: result,
  });
});

module.exports = {
  createOrder,
  cancelOrder,
};
