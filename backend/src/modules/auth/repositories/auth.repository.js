const { prisma } = require('../../../common/config/prisma');

async function findUserByEmail(email) {
  return prisma.user.findUnique({
    where: { email },
  });
}

async function createUser(userData) {
  return prisma.user.create({
    data: userData,
  });
}

module.exports = {
  findUserByEmail,
  createUser,
};