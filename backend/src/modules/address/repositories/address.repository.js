const { prisma } = require('../../../common/config/prisma');

function findManyByUserId(userId) {
  return prisma.addresses.findMany({
    where: { user_id: userId },
    orderBy: [
      { is_default: 'desc' },
      { created_at: 'desc' },
    ],
  });
}

function findByIdAndUserId(id, userId) {
  return prisma.addresses.findFirst({
    where: { id, user_id: userId },
  });
}

function create(userId, data) {
  return prisma.$transaction(async (tx) => {
    if (data.is_default) {
      await tx.addresses.updateMany({
        where: { user_id: userId, is_default: true },
        data: { is_default: false, updated_at: new Date() },
      });
    }

    return tx.addresses.create({
      data: {
        ...data,
        user_id: userId,
      },
    });
  });
}

function update(id, userId, data) {
  return prisma.$transaction(async (tx) => {
    const address = await tx.addresses.findFirst({
      where: { id, user_id: userId },
      select: { id: true },
    });

    if (!address) return null;

    if (data.is_default) {
      await tx.addresses.updateMany({
        where: {
          user_id: userId,
          is_default: true,
          NOT: { id },
        },
        data: { is_default: false, updated_at: new Date() },
      });
    }

    return tx.addresses.update({
      where: { id },
      data: { ...data, updated_at: new Date() },
    });
  });
}

function remove(id, userId) {
  return prisma.addresses.deleteMany({
    where: { id, user_id: userId },
  });
}

module.exports = {
  findManyByUserId,
  findByIdAndUserId,
  create,
  update,
  remove,
};
