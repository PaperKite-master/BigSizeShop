const { AppError } = require('../../../common/errors/app-error');
const orderRepository = require('../repositories/order.repository');
const cartService = require('../../cart/services/cart.service');
const { createOrderDto } = require('../dto/order.dto');

async function createOrder(userId, payload) {
  const data = createOrderDto(payload);
  
  // Get cart
  const cart = await cartService.getCart(userId);
  
  if (!cart.items || cart.items.length === 0) {
    throw new AppError('Cart is empty', 400);
  }

  // Double check stock for all items
  for (const item of cart.items) {
    const product = item.products;
    
    if (item.variant_id) {
      const variant = item.product_variants;
      if (!variant || variant.stock < item.quantity) {
        throw new AppError(`Not enough stock for variant of product: ${product.name}`, 400);
      }
    } else {
      if (!product || product.stock < item.quantity) {
        throw new AppError(`Not enough stock for product: ${product?.name}`, 400);
      }
    }
  }

  // Use the transaction in repository to create order and reduce stock
  const order = await orderRepository.createOrderFromCart(
    userId, 
    data, 
    cart.items, 
    cart.totalPrice
  );

  return order;
}

async function cancelOrder(userId, orderId) {
  const order = await orderRepository.findByIdAndUserId(orderId, userId);
  
  if (!order) {
    throw new AppError('Order not found', 404);
  }

  if (order.status !== 'PENDING') {
    throw new AppError(`Cannot cancel order in ${order.status} status. Only PENDING orders can be cancelled.`, 400);
  }

  // Use transaction to cancel order and restore stock
  return orderRepository.cancelOrderAndRestoreStock(order.id, order.order_items);
}

async function getUserOrders(userId) {
  return orderRepository.findManyByUserId(userId);
}

module.exports = {
  createOrder,
  cancelOrder,
  getUserOrders
};
