const { AppError } = require('../../../common/errors/app-error');
const cartRepository = require('../repositories/cart.repository');
const productRepository = require('../../product/repositories/product.repository');
const { createCartItemDto, updateCartItemDto } = require('../dto/cart.dto');

async function getCart(userId) {
  const items = await cartRepository.findByUserId(userId);
  
  let totalPrice = 0;
  const formattedItems = items.map(item => {
    // If variant has specific price, use it, otherwise use product price
    const unitPrice = item.product_variants?.price ? parseFloat(item.product_variants.price) : parseFloat(item.products.price);
    const itemTotal = unitPrice * item.quantity;
    totalPrice += itemTotal;
    
    return {
      ...item,
      unitPrice,
      itemTotal
    };
  });

  return {
    items: formattedItems,
    totalPrice
  };
}

async function addItem(userId, payload) {
  const data = createCartItemDto(payload);
  
  const product = await productRepository.findById(data.productId);
  if (!product) {
    throw new AppError('Product not found', 404);
  }

  if (product.is_active !== true) {
    throw new AppError('Product is not available', 400);
  }

  let availableStock = product.stock ?? 0;
  if (data.variantId) {
    const variant = product.product_variants.find(v => v.id === data.variantId);
    if (!variant || variant.product_id !== product.id) {
      throw new AppError('Variant not found', 404);
    }
    availableStock = variant.stock ?? 0;
  }

  if (availableStock < data.quantity) {
    throw new AppError(
      data.variantId ? 'Not enough stock for this variant' : 'Not enough stock available',
      400,
    );
  }

  const existingItem = await cartRepository.findUniqueItem(
    userId,
    data.productId,
    data.variantId ?? null,
  );
  
  if (existingItem) {
    const newQuantity = existingItem.quantity + data.quantity;
    
    if (availableStock < newQuantity) {
      throw new AppError(
        data.variantId ? 'Not enough stock for this variant' : 'Not enough stock available',
        400,
      );
    }

    return cartRepository.update(existingItem.id, { quantity: newQuantity });
  }

  // Create new item
  return cartRepository.create({
    userId,
    productId: data.productId,
    variant_id: data.variantId,
    quantity: data.quantity
  });
}

async function updateItemQuantity(userId, cartItemId, payload) {
  const data = updateCartItemDto(payload);
  
  const cartItem = await cartRepository.findByIdAndUserId(cartItemId, userId);
  if (!cartItem) {
    throw new AppError('Cart item not found', 404);
  }

  const product = cartItem.products;
  if (product.is_active !== true) {
    throw new AppError('Product is not available', 400);
  }

  if (cartItem.variant_id) {
    const variant = cartItem.product_variants;
    if (!variant || variant.product_id !== product.id) {
      throw new AppError('Variant does not belong to this product', 400);
    }
    if ((variant.stock ?? 0) < data.quantity) {
      throw new AppError('Not enough stock for this variant', 400);
    }
  } else {
    if ((product.stock ?? 0) < data.quantity) {
      throw new AppError('Not enough stock available', 400);
    }
  }

  return cartRepository.update(cartItemId, { quantity: data.quantity });
}

async function removeItem(userId, cartItemId) {
  const cartItem = await cartRepository.findByIdAndUserId(cartItemId, userId);
  if (!cartItem) {
    throw new AppError('Cart item not found', 404);
  }

  return cartRepository.remove(cartItemId);
}

module.exports = {
  getCart,
  addItem,
  updateItemQuantity,
  removeItem,
};
