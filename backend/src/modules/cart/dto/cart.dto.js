const { AppError } = require('../../../common/errors/app-error');

function parseQuantity(value) {
  const quantity = Number(value);

  if (!Number.isFinite(quantity) || !Number.isInteger(quantity) || quantity <= 0) {
    throw new AppError('Quantity must be a positive integer', 400);
  }

  return quantity;
}

function createCartItemDto(payload) {
  const { productId, quantity = 1, variantId } = payload;

  if (typeof productId !== 'string' || !productId.trim()) {
    throw new AppError('Product ID is required', 400);
  }

  return {
    productId: productId.trim(),
    quantity: parseQuantity(quantity),
    variantId: typeof variantId === 'string' && variantId.trim()
      ? variantId.trim()
      : null,
  };
}

function updateCartItemDto(payload) {
  const { quantity } = payload;

  if (quantity === undefined) {
    throw new AppError('Quantity is required', 400);
  }

  return {
    quantity: parseQuantity(quantity),
  };
}

module.exports = {
  createCartItemDto,
  updateCartItemDto,
};
