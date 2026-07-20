const { AppError } = require('../../../common/errors/app-error');
const orderRepository = require('../repositories/order.repository');
const cartService = require('../../cart/services/cart.service');
const addressRepository = require('../../address/repositories/address.repository');
const { createOrderDto } = require('../dto/order.dto');
const { sendPushNotification } = require('../../notification/services/notification.service');

const SHIPPING_FEE = 30000;

const VALID_TRANSITIONS = {
  'PENDING': ['CONFIRMED', 'CANCELLED'],
  'CONFIRMED': ['SHIPPING', 'CANCELLED'],
  'SHIPPING': ['DELIVERED', 'CANCELLED'],
  'DELIVERED': [],
  'CANCELLED': []
};

async function createOrder(userId, payload) {
  const data = createOrderDto(payload);

  if (data.addressId) {
    const address = await addressRepository.findByIdAndUserId(data.addressId, userId);
    if (!address) {
      throw new AppError('Delivery address not found', 404);
    }

    data.address = [
      `${address.receiver_name} (${address.receiver_phone})`,
      address.street_address,
      address.ward,
      address.district,
      address.province,
    ].filter(Boolean).join(', ');
  }
  
  // Get cart
  const cart = await cartService.getCart(userId);
  
  if (!cart.items || cart.items.length === 0) {
    throw new AppError('Cart is empty', 400);
  }

  // Double check stock for all items
  for (const item of cart.items) {
    const product = item.products;

    if (!product || product.is_active !== true) {
      throw new AppError('Product is not available', 400);
    }
    
    if (item.variant_id) {
      const variant = item.product_variants;
      if (
        !variant
        || variant.product_id !== item.productId
        || (variant.stock ?? 0) < item.quantity
      ) {
        throw new AppError(`Not enough stock for variant of product: ${product.name}`, 400);
      }
    } else {
      if ((product.stock ?? 0) < item.quantity) {
        throw new AppError(`Not enough stock for product: ${product?.name}`, 400);
      }
    }
  }

  // Use the transaction in repository to create order and reduce stock
  const order = await orderRepository.createOrderFromCart(
    userId, 
    data, 
    cart.items, 
    cart.totalPrice + SHIPPING_FEE
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
  const cancelledOrder = await orderRepository.cancelOrderAndRestoreStock(order.id, order.order_items, order.status);

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

async function getAdminOrders() {
  return orderRepository.findManyForAdmin();
}

async function updateOrderStatus(orderId, statusInput) {
  const status = String(statusInput || '').toUpperCase();
  
  const order = await orderRepository.findById(orderId);
  
  if (!order) {
    throw new AppError('Order not found', 404);
  }

  const currentStatus = order.status || 'PENDING';

  if (!VALID_TRANSITIONS[currentStatus]) {
    throw new AppError(`Order has invalid status: ${currentStatus}`, 400);
  }

  // Validate status existence
  if (!VALID_TRANSITIONS[status]) {
    throw new AppError(`Invalid status: ${statusInput}`, 400);
  }

  // Validate state transition
  const allowedTransitions = VALID_TRANSITIONS[currentStatus];
  if (!allowedTransitions.includes(status)) {
    throw new AppError(`Cannot transition order from ${currentStatus} to ${status}.`, 400);
  }

  let updatedOrder;
  if (status === 'CANCELLED') {
    // If cancelling, we must restore product stock
    updatedOrder = await orderRepository.updateStatusAndRestoreStock(
      orderId, 
      order.order_items, 
      currentStatus, 
      'CANCELLED', 
      'Cập nhật trạng thái đơn hàng sang CANCELLED bởi Admin/Hệ thống.'
    );
  } else {
    // Standard status update with history log
    updatedOrder = await orderRepository.updateStatus(
      orderId, 
      currentStatus, 
      status, 
      `Cập nhật trạng thái đơn hàng sang ${status} bởi Admin/Hệ thống.`
    );
  }

  // Send push notification when status changes
  let title = 'Cập nhật trạng thái đơn hàng';
  let body = `Đơn hàng #${orderId.substring(0, 8)} đã thay đổi trạng thái sang: ${status}.`;

  if (status === 'CONFIRMED') {
    title = 'Đơn hàng đã xác nhận';
    body = `Đơn hàng #${orderId.substring(0, 8)} của bạn đã được xác nhận.`;
  } else if (status === 'SHIPPING') {
    title = 'Đơn hàng đang vận chuyển';
    body = `Đơn hàng #${orderId.substring(0, 8)} đã được bàn giao cho đơn vị vận chuyển.`;
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
  getAdminOrders,
  updateOrderStatus,
};
