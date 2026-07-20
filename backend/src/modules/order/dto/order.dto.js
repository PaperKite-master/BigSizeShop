const { AppError } = require('../../../common/errors/app-error');

function createOrderDto(payload) {
  const addressId = typeof payload.addressId === 'string' ? payload.addressId.trim() : '';
  const address = typeof payload.address === 'string' ? payload.address.trim() : '';
  const paymentMethod = String(payload.paymentMethod || 'COD').trim().toUpperCase();

  if (!addressId && !address) {
    throw new AppError('Delivery address is required', 400);
  }

  if (!['COD', 'BANK'].includes(paymentMethod)) {
    throw new AppError('Payment method must be COD or BANK', 400);
  }

  return {
    addressId: addressId || null,
    address: address || null,
    paymentMethod,
  };
}

module.exports = {
  createOrderDto,
};
