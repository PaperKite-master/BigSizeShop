const { AppError } = require('../../../common/errors/app-error');

function createCartItemDto(payload) {
  const { productId, quantity = 1, variantId } = payload;

  if (!productId) {
    throw new AppError('Product ID is required', 400);
  }

  if (quantity < 1) {
    throw new AppError('Quantity must be at least 1', 400);
  }

  return {
    productId,
    quantity: parseInt(quantity, 10),
    variantId,
  };
}

function updateCartItemDto(payload) {
  const { quantity } = payload;

  if (quantity === undefined) {
    throw new AppError('Quantity is required', 400);
  }

  if (quantity < 1) {
    throw new AppError('Quantity must be at least 1', 400);
  }

  return {
    quantity: parseInt(quantity, 10),
  };
}

module.exports = {
  createCartItemDto,
  updateCartItemDto,
};
