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

const getUserOrders = asyncHandler(async (req, res) => {
  const result = await orderService.getUserOrders(req.user.id);

  res.json({
    message: 'User orders retrieved successfully',
    data: result,
  });
});

const updateOrderStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  const result = await orderService.updateOrderStatus(req.params.id, status);

  res.json({
    message: 'Order status updated successfully',
    data: result,
  });
});

module.exports = {
  createOrder,
  cancelOrder,
  getUserOrders,
  updateOrderStatus,
};
