const { prisma } = require('../../../common/config/prisma');

const CART_INCLUDE = {
  products: {
    select: {
      id: true,
      name: true,
      price: true,
      imageUrl: true,
      stock: true,
    }
  },
  product_variants: true,
};

async function findByUserId(userId) {
  return prisma.cartItem.findMany({
    where: { userId },
    include: CART_INCLUDE,
    orderBy: { created_at: 'desc' },
  });
}

async function findUniqueItem(userId, productId) {
  return prisma.cartItem.findUnique({
    where: {
      userId_productId: {
        userId,
        productId,
      },
    },
    include: CART_INCLUDE,
  });
}

async function findByIdAndUserId(id, userId) {
  return prisma.cartItem.findFirst({
    where: { id, userId },
    include: CART_INCLUDE,
  });
}

async function create(data) {
  return prisma.cartItem.create({
    data,
    include: CART_INCLUDE,
  });
}

async function update(id, data) {
  return prisma.cartItem.update({
    where: { id },
    data,
    include: CART_INCLUDE,
  });
}

async function remove(id) {
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
  findByUserId,
  findUniqueItem,
  findByIdAndUserId,
  create,
  update,
  remove,
  clearCart,
};
