const { prisma } = require('../../../common/config/prisma');

async function createNotification(userId, title, content) {
  return prisma.notification.create({
    data: {
      userId,
      title,
      content,
    },
  });
}

async function createManyNotifications(notificationsData) {
  return prisma.notification.createMany({
    data: notificationsData,
  });
}

module.exports = {
  createNotification,
  createManyNotifications,
};
