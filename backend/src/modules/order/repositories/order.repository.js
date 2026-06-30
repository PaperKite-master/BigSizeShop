const { prisma } = require('../../../common/config/prisma');

async function findManyByUser(userId) {
  return prisma.order.findMany({
    where: { userId },
    include: {
      order_items: {
        include: {
          products: {
            include: {
              product_images: true,
            },
          },
          product_variants: true,
        },
      },
    },
    orderBy: {
      createdAt: 'desc',
    },
  });
}

async function findById(id) {
  return prisma.order.findUnique({
    where: { id },
    include: {
      order_items: {
        include: {
          products: true,
          product_variants: true,
        },
      },
    },
  });
}

async function createOrderTransaction(userId, orderData, items) {
  return prisma.$transaction(async (tx) => {
    // 1. Create the Order
    const order = await tx.order.create({
      data: {
        userId,
        totalPrice: orderData.totalPrice,
        address: orderData.address,
        paymentMethod: orderData.paymentMethod,
        status: 'PENDING',
      },
    });

    // 2. Process each item (decrement stock & create OrderItem)
    for (const item of items) {
      // Create OrderItem
      await tx.orderItem.create({
        data: {
          orderId: order.id,
          productId: item.productId,
          quantity: item.quantity,
          price: item.price,
          variant_id: item.variantId || null,
        },
      });

      // Decrement stock
      if (item.variantId) {
        // Decrement variant stock
        const variant = await tx.product_variants.findUnique({
          where: { id: item.variantId },
        });
        if (!variant || variant.stock < item.quantity) {
          throw new Error(`Insufficient stock for variant ${variant?.variant_name || item.variantId}`);
        }
        await tx.product_variants.update({
          where: { id: item.variantId },
          data: { stock: variant.stock - item.quantity },
        });
      } else {
        // Decrement product stock
        const product = await tx.product.findUnique({
          where: { id: item.productId },
        });
        if (!product || product.stock < item.quantity) {
          throw new Error(`Insufficient stock for product ${product?.name || item.productId}`);
        }
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: product.stock - item.quantity },
        });
      }
    }

    // 3. Clear User's Cart
    await tx.cartItem.deleteMany({
      where: { userId },
    });

    return tx.order.findUnique({
      where: { id: order.id },
      include: {
        order_items: {
          include: {
            products: {
              include: {
                product_images: true,
              },
            },
            product_variants: true,
          },
        },
      },
    });
  });
}

module.exports = {
  findManyByUser,
  findById,
  createOrderTransaction,
};
