const { AppError } = require('../../../common/errors/app-error');
const { prisma } = require('../../../common/config/prisma');
const orderRepository = require('../repositories/order.repository');
const cartRepository = require('../../cart/repositories/cart.repository');

async function list(userId) {
  return orderRepository.findManyByUser(userId);
}

async function placeOrder(userId, { addressId, addressText, paymentMethod = 'COD' }) {
  // 1. Fetch user's cart items
  const cartItems = await cartRepository.findManyByUser(userId);
  if (!cartItems.length) {
    throw new AppError('Cart is empty', 400);
  }

  // 2. Resolve shipping address
  let finalAddress = '';
  if (addressId) {
    const addressRecord = await prisma.addresses.findUnique({
      where: { id: addressId },
    });
    if (!addressRecord || addressRecord.user_id !== userId) {
      throw new AppError('Address not found or unauthorized', 404);
    }
    const { receiver_name, receiver_phone, street_address, ward, district, province } = addressRecord;
    finalAddress = `${receiver_name} (${receiver_phone}) - ${street_address}, ${ward || ''}, ${district || ''}, ${province || ''}`.replace(/,\s*,/g, ',').trim();
  } else if (addressText) {
    finalAddress = addressText;
  } else {
    throw new AppError('Delivery address is required', 400);
  }

  // 3. Process cart items: calculate prices and prepare order items
  let totalPrice = 0;
  const orderItemsData = [];

  for (const item of cartItems) {
    let itemPrice = 0;

    // Use variant price if available, otherwise use product price
    if (item.variant_id && item.product_variants) {
      itemPrice = item.product_variants.price
        ? parseFloat(item.product_variants.price.toString())
        : parseFloat(item.products.price.toString());
      
      // Stock check
      if (item.product_variants.stock < item.quantity) {
        throw new AppError(`Insufficient stock for variant ${item.product_variants.variant_name}. Available: ${item.product_variants.stock}`, 400);
      }
    } else {
      itemPrice = parseFloat(item.products.price.toString());

      // Stock check
      if (item.products.stock < item.quantity) {
        throw new AppError(`Insufficient stock for product ${item.products.name}. Available: ${item.products.stock}`, 400);
      }
    }

    totalPrice += itemPrice * item.quantity;
    orderItemsData.push({
      productId: item.productId,
      quantity: item.quantity,
      price: itemPrice,
      variantId: item.variant_id,
    });
  }

  // 4. Execute creation transaction
  try {
    const order = await orderRepository.createOrderTransaction(
      userId,
      {
        totalPrice,
        address: finalAddress,
        paymentMethod,
      },
      orderItemsData
    );
    return order;
  } catch (err) {
    throw new AppError(err.message, 400);
  }
}

module.exports = {
  list,
  placeOrder,
};
