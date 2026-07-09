const { prisma } = require('../../../common/config/prisma');

const SENDER_SELECT = {
  id: true,
  fullName: true,
  email: true,
  avatar: true,
  role: true,
};

const MESSAGE_INCLUDE = {
  users: {
    select: SENDER_SELECT,
  },
};

async function findChatById(chatId) {
  return prisma.chats.findUnique({
    where: { id: chatId },
    include: {
      users_chats_customer_idTousers: {
        select: SENDER_SELECT,
      },
      users_chats_admin_idTousers: {
        select: SENDER_SELECT,
      },
    },
  });
}

async function findChatsForUser(userId, role) {
  if (role === 'ADMIN') {
    return prisma.chats.findMany({
      orderBy: { created_at: 'desc' },
      include: {
        users_chats_customer_idTousers: {
          select: SENDER_SELECT,
        },
        users_chats_admin_idTousers: {
          select: SENDER_SELECT,
        },
        messages: {
          orderBy: { sentAt: 'desc' },
          take: 1,
          include: MESSAGE_INCLUDE,
        },
      },
    });
  }

  return prisma.chats.findMany({
    where: { customer_id: userId },
    orderBy: { created_at: 'desc' },
    include: {
      users_chats_customer_idTousers: {
        select: SENDER_SELECT,
      },
      users_chats_admin_idTousers: {
        select: SENDER_SELECT,
      },
      messages: {
        orderBy: { sentAt: 'desc' },
        take: 1,
        include: MESSAGE_INCLUDE,
      },
    },
  });
}

async function findOpenChatForCustomer(customerId) {
  return prisma.chats.findFirst({
    where: { customer_id: customerId },
    orderBy: { created_at: 'desc' },
    include: {
      users_chats_customer_idTousers: {
        select: SENDER_SELECT,
      },
      users_chats_admin_idTousers: {
        select: SENDER_SELECT,
      },
    },
  });
}

async function createChat(customerId, adminId = null) {
  return prisma.chats.create({
    data: {
      customer_id: customerId,
      admin_id: adminId,
    },
    include: {
      users_chats_customer_idTousers: {
        select: SENDER_SELECT,
      },
      users_chats_admin_idTousers: {
        select: SENDER_SELECT,
      },
    },
  });
}

async function assignAdmin(chatId, adminId) {
  return prisma.chats.update({
    where: { id: chatId },
    data: { admin_id: adminId },
    include: {
      users_chats_customer_idTousers: {
        select: SENDER_SELECT,
      },
      users_chats_admin_idTousers: {
        select: SENDER_SELECT,
      },
    },
  });
}

async function findMessagesByChatId(chatId) {
  return prisma.message.findMany({
    where: { chatId },
    orderBy: { sentAt: 'asc' },
    include: MESSAGE_INCLUDE,
  });
}

async function createMessage({ chatId, senderId, content }) {
  return prisma.message.create({
    data: {
      chatId,
      senderId,
      content,
    },
    include: MESSAGE_INCLUDE,
  });
}

module.exports = {
  findChatById,
  findChatsForUser,
  findOpenChatForCustomer,
  createChat,
  assignAdmin,
  findMessagesByChatId,
  createMessage,
};
