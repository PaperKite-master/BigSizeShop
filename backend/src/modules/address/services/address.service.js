const { AppError } = require('../../../common/errors/app-error');
const addressRepository = require('../repositories/address.repository');

async function list(userId) {
  return addressRepository.findManyByUser(userId);
}

async function create(userId, payload) {
  const { receiverName, receiverPhone, streetAddress } = payload;
  if (!receiverName || !receiverPhone || !streetAddress) {
    throw new AppError('Receiver name, phone, and street address are required', 400);
  }

  // If this is the first address, make it default automatically
  const existing = await addressRepository.findManyByUser(userId);
  const isFirst = existing.length === 0;

  return addressRepository.createAddress(userId, {
    ...payload,
    is_default: isFirst ? true : payload.isDefault,
  });
}

async function update(userId, addressId, payload) {
  const address = await addressRepository.findById(addressId);
  if (!address || address.user_id !== userId) {
    throw new AppError('Address not found', 404);
  }

  return addressRepository.updateAddress(addressId, userId, {
    ...payload,
    is_default: payload.isDefault !== undefined ? payload.isDefault : address.is_default,
  });
}

async function remove(userId, addressId) {
  const address = await addressRepository.findById(addressId);
  if (!address || address.user_id !== userId) {
    throw new AppError('Address not found', 404);
  }

  await addressRepository.deleteAddress(addressId);

  // If the deleted address was default, make another one default
  if (address.is_default) {
    const existing = await addressRepository.findManyByUser(userId);
    if (existing.length > 0) {
      await addressRepository.updateAddress(existing[0].id, userId, {
        ...existing[0],
        isDefault: true,
      });
    }
  }

  return { message: 'Address deleted successfully' };
}

module.exports = {
  list,
  create,
  update,
  remove,
};
