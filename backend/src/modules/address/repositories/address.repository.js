const { prisma } = require('../../../common/config/prisma');

async function findManyByUser(userId) {
  return prisma.addresses.findMany({
    where: { user_id: userId },
    orderBy: {
      is_default: 'desc',
    },
  });
}

async function findById(id) {
  return prisma.addresses.findUnique({
    where: { id },
  });
}

async function unsetDefaults(userId) {
  return prisma.addresses.updateMany({
    where: { user_id: userId },
    data: { is_default: false },
  });
}

async function createAddress(userId, data) {
  if (data.is_default) {
    await unsetDefaults(userId);
  }

  return prisma.addresses.create({
    data: {
      user_id: userId,
      receiver_name: data.receiverName,
      receiver_phone: data.receiverPhone,
      province: data.province,
      district: data.district,
      ward: data.ward,
      street_address: data.streetAddress,
      is_default: data.is_default || false,
    },
  });
}

async function updateAddress(id, userId, data) {
  if (data.is_default) {
    await unsetDefaults(userId);
  }

  return prisma.addresses.update({
    where: { id },
    data: {
      receiver_name: data.receiverName,
      receiver_phone: data.receiverPhone,
      province: data.province,
      district: data.district,
      ward: data.ward,
      street_address: data.streetAddress,
      is_default: data.is_default,
    },
  });
}

async function deleteAddress(id) {
  return prisma.addresses.delete({
    where: { id },
  });
}

module.exports = {
  findManyByUser,
  findById,
  createAddress,
  updateAddress,
  deleteAddress,
  unsetDefaults,
};
