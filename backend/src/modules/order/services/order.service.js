const { AppError } = require('../../../common/errors/app-error');
const orderRepository = require('../repositories/order.repository');
const cartService = require('../../cart/services/cart.service');
const { createOrderDto } = require('../dto/order.dto');
const { sendPushNotification } = require('../../notification/services/notification.service');

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
  const cancelledOrder = await orderRepository.cancelOrderAndRestoreStock(order.id, order.order_items);

  // Send push notification
  sendPushNotification(
    userId,
    'Đơn hàng đã hủy',
    `Đơn hàng #${orderId.substring(0, 8)} của bạn đã được hủy thành công.`,
    { orderId, status: 'CANCELLED' }
  ).catch(err => console.error('Failed to send order cancellation push notification:', err));

  return cancelledOrder;
}

async function getUserOrders(userId) {
  return orderRepository.findManyByUserId(userId);
}

async function updateOrderStatus(orderId, status) {
  const order = await orderRepository.findById(orderId);
  
  if (!order) {
    throw new AppError('Order not found', 404);
  }

  const updatedOrder = await orderRepository.updateStatus(orderId, status);

  // Send push notification when status changes
  let title = 'Cập nhật trạng thái đơn hàng';
  let body = `Đơn hàng #${orderId.substring(0, 8)} đã thay đổi trạng thái sang: ${status}.`;

  if (status === 'PROCESSING') {
    title = 'Đơn hàng đang xử lý';
    body = `Đơn hàng #${orderId.substring(0, 8)} đang được chuẩn bị và xử lý.`;
  } else if (status === 'SHIPPED') {
    title = 'Đơn hàng đang được giao';
    body = `Đơn hàng #${orderId.substring(0, 8)} đã được giao cho đơn vị vận chuyển.`;
  } else if (status === 'DELIVERED') {
    title = 'Giao hàng thành công';
    body = `Đơn hàng #${orderId.substring(0, 8)} đã được giao thành công. Cảm ơn bạn!`;
  } else if (status === 'CANCELLED') {
    title = 'Đơn hàng đã hủy';
    body = `Đơn hàng #${orderId.substring(0, 8)} của bạn đã bị hủy.`;
  }

  sendPushNotification(
    order.userId,
    title,
    body,
    { orderId, status }
  ).catch(err => console.error('Failed to send order status push notification:', err));

  return updatedOrder;
}

module.exports = {
  createOrder,
  cancelOrder,
  getUserOrders,
  updateOrderStatus,
};
