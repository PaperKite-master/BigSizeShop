const { asyncHandler } = require('../../../common/utils/async-handler');
const cartService = require('../services/cart.service');

const getCart = asyncHandler(async (req, res) => {
  const result = await cartService.getCart(req.user.id);

  res.json({
    message: 'Cart fetched successfully',
    data: result.items,
    meta: {
      totalPrice: result.totalPrice,
    },
  });
});

const addItem = asyncHandler(async (req, res) => {
  const result = await cartService.addItem(req.user.id, req.body);

  res.status(201).json({
    message: 'Item added to cart',
    data: result,
  });
});

const updateItemQuantity = asyncHandler(async (req, res) => {
  const result = await cartService.updateItemQuantity(req.user.id, req.params.id, req.body);

  res.json({
    message: 'Cart item quantity updated',
    data: result,
  });
});

const removeItem = asyncHandler(async (req, res) => {
  await cartService.removeItem(req.user.id, req.params.id);

  res.json({
    message: 'Item removed from cart',
  });
});

module.exports = {
  getCart,
  addItem,
  updateItemQuantity,
  removeItem,
};
