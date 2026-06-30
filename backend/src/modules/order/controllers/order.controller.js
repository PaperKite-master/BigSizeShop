const { asyncHandler } = require('../../../common/utils/async-handler');
const orderService = require('../services/order.service');

const list = asyncHandler(async (req, res) => {
  const orders = await orderService.list(req.user.id);
  res.json({
    message: 'Orders retrieved successfully',
    data: orders,
  });
});

const placeOrder = asyncHandler(async (req, res) => {
  const order = await orderService.placeOrder(req.user.id, req.body);
  res.status(201).json({
    message: 'Order placed successfully',
    data: order,
  });
});

module.exports = {
  list,
  placeOrder,
};
