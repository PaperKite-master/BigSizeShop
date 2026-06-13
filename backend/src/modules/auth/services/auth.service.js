const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { AppError } = require('../../../common/errors/app-error');
const { createUser, findUserByEmail, findUserById } = require('../repositories/auth.repository');
const { loginDto, registerDto } = require('../dto/auth.dto');

const SALT_ROUNDS = 10;
const TOKEN_EXPIRY = '7d';

function signToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role || 'USER',
    },
    process.env.JWT_SECRET,
    { expiresIn: TOKEN_EXPIRY },
  );
}

async function register(payload) {
  const data = registerDto(payload);

  if (!data.email || !data.password || !data.fullName) {
    throw new AppError('Missing required registration fields', 400);
  }

  const existingUser = await findUserByEmail(data.email);

  if (existingUser) {
    throw new AppError('Email already exists', 409);
  }

  const hashedPassword = await bcrypt.hash(data.password, SALT_ROUNDS);

  return createUser({
    ...data,
    password: hashedPassword,
  });
}

async function login(payload) {
  const data = loginDto(payload);

  if (!data.email || !data.password) {
    throw new AppError('Email and password are required', 400);
  }

  const user = await findUserByEmail(data.email);

  if (!user) {
    throw new AppError('Invalid email or password', 401);
  }

  const isValidPassword = await bcrypt.compare(data.password, user.password);

  if (!isValidPassword) {
    throw new AppError('Invalid email or password', 401);
  }

  const token = signToken(user);
  const { password, ...publicUser } = user;

  return { token, user: publicUser };
}

async function getMe(userId) {
  const user = await findUserById(userId);

  if (!user) {
    throw new AppError('User not found', 404);
  }

  return user;
}

function logout() {
  return { message: 'Logged out successfully' };
}

module.exports = {
  register,
  login,
  getMe,
  logout,
};
