const { asyncHandler } = require('../../../common/utils/async-handler');
const cartService = require('../services/cart.service');

const getCart = asyncHandler(async (req, res) => {
  const cartItems = await cartService.getCart(req.user.id);
  res.json({
    message: 'Cart retrieved successfully',
    data: cartItems,
  });
});

const addToCart = asyncHandler(async (req, res) => {
  const cartItem = await cartService.addToCart(req.user.id, req.body);
  res.status(201).json({
    message: 'Product added to cart successfully',
    data: cartItem,
  });
});

const updateQuantity = asyncHandler(async (req, res) => {
  const cartItem = await cartService.updateQuantity(req.user.id, req.params.id, req.body.quantity);
  res.json({
    message: 'Cart item quantity updated successfully',
    data: cartItem,
  });
});

const removeFromCart = asyncHandler(async (req, res) => {
  const result = await cartService.removeFromCart(req.user.id, req.params.id);
  res.json({
    message: result.message,
  });
});

module.exports = {
  getCart,
  addToCart,
  updateQuantity,
  removeFromCart,
};
