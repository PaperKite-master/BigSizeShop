const { AppError } = require('../../../common/errors/app-error');
const { createUser, findUserByEmail } = require('../repositories/auth.repository');
const { registerDto } = require('../dto/auth.dto');

async function register(payload) {
  const data = registerDto(payload);

  if (!data.email || !data.password || !data.fullName) {
    throw new AppError('Missing required registration fields', 400);
  }

  const existingUser = await findUserByEmail(data.email);

  if (existingUser) {
    throw new AppError('Email already exists', 409);
  }

  return createUser(data);
}

module.exports = {
  register,
};