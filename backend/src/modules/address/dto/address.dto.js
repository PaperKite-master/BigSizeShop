const { AppError } = require('../../../common/errors/app-error');

const REQUIRED_FIELDS = [
  'receiverName',
  'receiverPhone',
  'streetAddress',
];

const OPTIONAL_FIELDS = ['province', 'district', 'ward'];

function addressDto(payload = {}) {
  const data = {};

  for (const field of REQUIRED_FIELDS) {
    if (typeof payload[field] !== 'string' || !payload[field].trim()) {
      throw new AppError(`${field} is required`, 400);
    }
    data[field] = payload[field].trim();
  }

  for (const field of OPTIONAL_FIELDS) {
    const value = payload[field];
    if (value != null && typeof value !== 'string') {
      throw new AppError(`${field} must be a string`, 400);
    }
    data[field] = typeof value === 'string' && value.trim()
      ? value.trim()
      : null;
  }

  if (payload.isDefault !== undefined && typeof payload.isDefault !== 'boolean') {
    throw new AppError('isDefault must be a boolean', 400);
  }

  return {
    receiver_name: data.receiverName,
    receiver_phone: data.receiverPhone,
    province: data.province,
    district: data.district,
    ward: data.ward,
    street_address: data.streetAddress,
    is_default: payload.isDefault ?? false,
  };
}

module.exports = { addressDto };
