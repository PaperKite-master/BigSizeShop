const { AppError } = require('../../../common/errors/app-error');
const { prisma } = require('../../../common/config/prisma');
const cartRepository = require('../repositories/cart.repository');

async function getCart(userId) {
  return cartRepository.findManyByUser(userId);
}

async function addToCart(userId, { productId, quantity = 1, variantId }) {
  if (!productId) {
    throw new AppError('Product ID is required', 400);
  }
  if (quantity <= 0) {
    throw new AppError('Quantity must be greater than 0', 400);
  }

  // 1. Verify product exists and is active
  const product = await prisma.product.findUnique({
    where: { id: productId },
  });

  if (!product || !product.is_active) {
    throw new AppError('Product not found or inactive', 404);
  }

  // 2. Verify variant exists if variantId is provided
  if (variantId) {
    const variant = await prisma.product_variants.findFirst({
      where: {
        id: variantId,
        product_id: productId,
      },
    });
    if (!variant) {
      throw new AppError('Product variant not found', 404);
    }
    if (variant.stock < quantity) {
      throw new AppError(`Insufficient stock. Only ${variant.stock} left.`, 400);
    }
  } else {
    if (product.stock < quantity) {
      throw new AppError(`Insufficient stock. Only ${product.stock} left.`, 400);
    }
  }

  // 3. Check if already in cart
  const existingItem = await cartRepository.findItem(userId, productId);

  if (existingItem) {
    const newQuantity = existingItem.quantity + quantity;
    // Verify stock again for new total quantity
    if (variantId) {
      const variant = await prisma.product_variants.findUnique({ where: { id: variantId } });
      if (variant.stock < newQuantity) {
        throw new AppError(`Cannot add more. Stock limit: ${variant.stock}`, 400);
      }
    } else {
      if (product.stock < newQuantity) {
        throw new AppError(`Cannot add more. Stock limit: ${product.stock}`, 400);
      }
    }

    return cartRepository.updateItem(existingItem.id, newQuantity, variantId);
  }

  // 4. Create new cart item
  return cartRepository.createItem(userId, productId, quantity, variantId);
}

async function updateQuantity(userId, cartItemId, quantity) {
  if (quantity <= 0) {
    throw new AppError('Quantity must be greater than 0', 400);
  }

  // Find existing cart item and make sure it belongs to the user
  const cartItem = await prisma.cartItem.findUnique({
    where: { id: cartItemId },
    include: { products: true, product_variants: true },
  });

  if (!cartItem || cartItem.userId !== userId) {
    throw new AppError('Cart item not found', 404);
  }

  // Check stock
  if (cartItem.variant_id) {
    if (cartItem.product_variants.stock < quantity) {
      throw new AppError(`Insufficient stock. Only ${cartItem.product_variants.stock} left.`, 400);
    }
  } else {
    if (cartItem.products.stock < quantity) {
      throw new AppError(`Insufficient stock. Only ${cartItem.products.stock} left.`, 400);
    }
  }

  return cartRepository.updateItem(cartItemId, quantity);
}

async function removeFromCart(userId, cartItemId) {
  const cartItem = await prisma.cartItem.findUnique({
    where: { id: cartItemId },
  });

  if (!cartItem || cartItem.userId !== userId) {
    throw new AppError('Cart item not found', 404);
  }

  await cartRepository.deleteItem(cartItemId);
  return { message: 'Item removed from cart' };
}

module.exports = {
  getCart,
  addToCart,
  updateQuantity,
  removeFromCart,
};
