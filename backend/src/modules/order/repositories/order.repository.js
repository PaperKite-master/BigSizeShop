const { prisma } = require('../../../common/config/prisma');

async function findByIdAndUserId(id, userId) {
  return prisma.order.findFirst({
    where: { id, userId },
    include: {
      order_items: {
        include: {
          products: true,
          product_variants: true,
        }
      }
    }
  });
}

async function updateStatus(id, status) {
  return prisma.order.update({
    where: { id },
    data: { status },
  });
}

// Complex transaction for creating order from cart
async function createOrderFromCart(userId, orderData, cartItems, totalPrice) {
  return prisma.$transaction(async (tx) => {
    // 1. Create the Order
    const order = await tx.order.create({
      data: {
        userId,
        totalPrice,
        address: orderData.address,
        paymentMethod: orderData.paymentMethod,
        status: 'PENDING',
        order_items: {
          create: cartItems.map(item => ({
            productId: item.productId,
            variant_id: item.variant_id,
            quantity: item.quantity,
            price: item.unitPrice // we passed this from service calculation
          }))
        }
      },
      include: {
        order_items: true
      }
    });

    // 2. Reduce stock for each product/variant
    for (const item of cartItems) {
      if (item.variant_id) {
        await tx.product_variants.update({
          where: { id: item.variant_id },
          data: {
            stock: {
              decrement: item.quantity
            }
          }
        });
      } else {
        await tx.product.update({
          where: { id: item.productId },
          data: {
            stock: {
              decrement: item.quantity
            }
          }
        });
      }
    }

    // 3. Clear the user's cart
    await tx.cartItem.deleteMany({
      where: { userId }
    });

    return order;
  });
}

// Restore stock when an order is cancelled
async function cancelOrderAndRestoreStock(orderId, orderItems) {
  return prisma.$transaction(async (tx) => {
    // 1. Update order status
    const order = await tx.order.update({
      where: { id: orderId },
      data: { status: 'CANCELLED' }
    });

    // 2. Restore stock
    for (const item of orderItems) {
      if (item.variant_id) {
        await tx.product_variants.update({
          where: { id: item.variant_id },
          data: {
            stock: {
              increment: item.quantity
            }
          }
        });
      } else {
        await tx.product.update({
          where: { id: item.productId },
          data: {
            stock: {
              increment: item.quantity
            }
          }
        });
      }
    }

    return order;
  });
}

module.exports = {
  findByIdAndUserId,
  updateStatus,
  createOrderFromCart,
  cancelOrderAndRestoreStock
};
