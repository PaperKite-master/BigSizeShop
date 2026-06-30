const { AppError } = require('../../../common/errors/app-error');

function createOrderDto(payload) {
  const { address, paymentMethod = 'COD' } = payload;

  if (!address) {
    throw new AppError('Delivery address is required', 400);
  }

  return {
    address,
    paymentMethod,
  };
}

module.exports = {
  createOrderDto,
};
