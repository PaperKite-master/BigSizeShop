const { AppError } = require('../../../common/errors/app-error');
const addressRepository = require('../repositories/address.repository');
const { addressDto } = require('../dto/address.dto');

function list(userId) {
  return addressRepository.findManyByUserId(userId);
}

function create(userId, payload) {
  return addressRepository.create(userId, addressDto(payload));
}

async function update(userId, id, payload) {
  const address = await addressRepository.update(id, userId, addressDto(payload));

  if (!address) {
    throw new AppError('Address not found', 404);
  }

  return address;
}

async function remove(userId, id) {
  const result = await addressRepository.remove(id, userId);

  if (result.count !== 1) {
    throw new AppError('Address not found', 404);
  }
}

module.exports = { list, create, update, remove };
