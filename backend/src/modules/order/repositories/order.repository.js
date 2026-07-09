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
      },
      order_status_logs: {
        orderBy: { created_at: 'asc' }
      }
    }
  });
}

async function updateStatus(id, fromStatus, toStatus, note = null) {
  return prisma.$transaction(async (tx) => {
    const order = await tx.order.update({
      where: { id },
      data: { status: toStatus },
    });

    await tx.order_status_logs.create({
      data: {
        order_id: id,
        from_status: fromStatus,
        to_status: toStatus,
        note,
      },
    });

    return order;
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
        paymentStatus: 'UNPAID',
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
        order_items: {
          include: {
            products: true,
            product_variants: true,
          }
        }
      }
    });

    // 2. Create Order Status Log for PENDING
    await tx.order_status_logs.create({
      data: {
        order_id: order.id,
        from_status: null,
        to_status: 'PENDING',
        note: 'Đơn hàng được tạo mới thành công.'
      }
    });

    // 3. Reduce stock for each product/variant
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

    // 4. Clear the user's cart
    await tx.cartItem.deleteMany({
      where: { userId }
    });

    return order;
  });
}

// Restore stock when an order is cancelled
async function cancelOrderAndRestoreStock(orderId, orderItems, fromStatus) {
  return prisma.$transaction(async (tx) => {
    // 1. Update order status
    const order = await tx.order.update({
      where: { id: orderId },
      data: { status: 'CANCELLED' }
    });

    // 2. Create the status log
    await tx.order_status_logs.create({
      data: {
        order_id: orderId,
        from_status: fromStatus,
        to_status: 'CANCELLED',
        note: 'Khách hàng yêu cầu hủy đơn hàng.'
      }
    });

    // 3. Restore stock
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

// Update status to Cancelled and restore stock (called by Admin/System updates)
async function updateStatusAndRestoreStock(orderId, orderItems, fromStatus, toStatus, note) {
  return prisma.$transaction(async (tx) => {
    // 1. Update order status
    const order = await tx.order.update({
      where: { id: orderId },
      data: { status: toStatus }
    });

    // 2. Create the status log
    await tx.order_status_logs.create({
      data: {
        order_id: orderId,
        from_status: fromStatus,
        to_status: toStatus,
        note,
      }
    });

    // 3. Restore stock
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

async function findManyByUserId(userId) {
  return prisma.order.findMany({
    where: { userId },
    include: {
      order_items: {
        include: {
          products: true,
          product_variants: true,
        }
      },
      order_status_logs: {
        orderBy: { created_at: 'asc' }
      }
    },
    orderBy: {
      createdAt: 'desc'
    }
  });
}

async function findById(id) {
  return prisma.order.findUnique({
    where: { id },
    include: {
      order_items: true,
      order_status_logs: {
        orderBy: { created_at: 'asc' }
      }
    },
  });
}

module.exports = {
  findByIdAndUserId,
  updateStatus,
  createOrderFromCart,
  cancelOrderAndRestoreStock,
  updateStatusAndRestoreStock,
  findManyByUserId,
  findById,
};
