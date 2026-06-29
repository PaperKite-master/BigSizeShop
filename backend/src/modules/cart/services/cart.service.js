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

  // Check overall product stock
  if (product.stock < data.quantity) {
    throw new AppError('Not enough stock available', 400);
  }

  // If using a variant, check variant stock
  if (data.variantId) {
    const variant = product.product_variants.find(v => v.id === data.variantId);
    if (!variant) {
      throw new AppError('Variant not found', 404);
    }
    if (variant.stock < data.quantity) {
      throw new AppError('Not enough stock for this variant', 400);
    }
  }

  // Check if item already exists in cart for this user
  const existingItem = await cartRepository.findUniqueItem(userId, data.productId);
  
  if (existingItem) {
    // Increment quantity
    const newQuantity = existingItem.quantity + data.quantity;
    
    // Check stock again for new quantity
    if (data.variantId) {
      const variant = product.product_variants.find(v => v.id === data.variantId);
      if (variant.stock < newQuantity) throw new AppError('Not enough stock for this variant', 400);
    } else {
      if (product.stock < newQuantity) throw new AppError('Not enough stock available', 400);
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

  // Check stock
  const product = cartItem.products;
  if (cartItem.variant_id) {
    // Assuming product_variants is populated in CART_INCLUDE (it is, but we need the variant stock)
    // For a robust check, we might need to fetch the variant again if CART_INCLUDE doesn't give us all variants
    const variant = cartItem.product_variants; 
    if (variant && variant.stock < data.quantity) {
      throw new AppError('Not enough stock for this variant', 400);
    }
  } else {
    if (product.stock < data.quantity) {
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
