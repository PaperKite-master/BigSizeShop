const { prisma } = require('../../../common/config/prisma');

const USER_PUBLIC_SELECT = {
  id: true,
  fullName: true,
  email: true,
  phone: true,
  avatar: true,
  role: true,
  createdAt: true,
  updated_at: true,
};

async function findUserByEmail(email) {
  return prisma.user.findUnique({
    where: { email },
  });
}

async function findUserById(id) {
  return prisma.user.findUnique({
    where: { id },
    select: USER_PUBLIC_SELECT,
  });
}

async function createUser(userData) {
  return prisma.user.create({
    data: userData,
    select: USER_PUBLIC_SELECT,
  });
}

module.exports = {
  findUserByEmail,
  findUserById,
  createUser,
};
