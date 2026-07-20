const { prisma } = require('../../../common/config/prisma');

const paymentFields = {
  id: true,
  userId: true,
  totalPrice: true,
  paymentMethod: true,
  paymentStatus: true,
  paymentTransactionId: true,
  paidAt: true,
};

function findOrderById(orderId) {
  return prisma.order.findUnique({
    where: { id: orderId },
    select: paymentFields,
  });
}

function findOrderByIdAndUserId(orderId, userId) {
  return prisma.order.findFirst({
    where: { id: orderId, userId },
    select: paymentFields,
  });
}

async function confirmPayment(orderId, transactionId) {
  return prisma.$transaction(async (tx) => {
    const update = await tx.order.updateMany({
      where: {
        id: orderId,
        paymentStatus: 'UNPAID',
        paymentTransactionId: null,
      },
      data: {
        paymentStatus: 'PAID',
        paymentTransactionId: transactionId,
        paidAt: new Date(),
      },
    });

    const order = await tx.order.findUnique({
      where: { id: orderId },
      select: paymentFields,
    });

    if (update.count === 1) {
      return { state: 'CONFIRMED', order };
    }
    if (order?.paymentStatus === 'PAID' && order.paymentTransactionId === transactionId) {
      return { state: 'ALREADY_CONFIRMED', order };
    }
    return { state: 'CONFLICT', order };
  });
}

module.exports = {
  confirmPayment,
  findOrderById,
  findOrderByIdAndUserId,
};
