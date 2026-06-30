const { prisma } = require('../../../common/config/prisma');

async function findManyByUser(userId) {
  return prisma.cartItem.findMany({
    where: { userId },
    include: {
      products: {
        include: {
          product_images: true,
        },
      },
      product_variants: true,
    },
    orderBy: {
      created_at: 'desc',
    },
  });
}

async function findItem(userId, productId) {
  return prisma.cartItem.findUnique({
    where: {
      userId_productId: {
        userId,
        productId,
      },
    },
  });
}

async function createItem(userId, productId, quantity, variantId) {
  return prisma.cartItem.create({
    data: {
      userId,
      productId,
      quantity,
      variant_id: variantId || null,
    },
    include: {
      products: true,
      product_variants: true,
    },
  });
}

async function updateItem(id, quantity, variantId) {
  return prisma.cartItem.update({
    where: { id },
    data: {
      quantity,
      ...(variantId !== undefined ? { variant_id: variantId || null } : {}),
    },
    include: {
      products: true,
      product_variants: true,
    },
  });
}

async function deleteItem(id) {
  return prisma.cartItem.delete({
    where: { id },
  });
}

async function clearCart(userId) {
  return prisma.cartItem.deleteMany({
    where: { userId },
  });
}

module.exports = {
  findManyByUser,
  findItem,
  createItem,
  updateItem,
  deleteItem,
  clearCart,
};
