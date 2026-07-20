const { AppError } = require('../../../common/errors/app-error');
const { findUserById } = require('../../auth/repositories/auth.repository');
const chatRepository = require('../repositories/chat.repository');
const { sendMessageDto } = require('../dto/chat.dto');

function normalizeRole(role) {
  return (role || 'USER').toUpperCase();
}

async function resolveCurrentUser(jwtUser) {
  const dbUser = await findUserById(jwtUser.id);

  if (!dbUser) {
    throw new AppError('User not found', 404);
  }

  return {
    id: dbUser.id,
    role: normalizeRole(dbUser.role),
  };
}

function formatUser(user) {
  if (!user) return null;

  return {
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    avatar: user.avatar,
    role: user.role,
  };
}

function formatMessage(message) {
  return {
    id: message.id,
    chatId: message.chatId,
    senderId: message.senderId,
    content: message.content,
    sentAt: message.sentAt,
    sender: formatUser(message.users),
  };
}

function formatChat(chat) {
  const lastMessage = chat.messages?.[0] ?? null;

  return {
    id: chat.id,
    customerId: chat.customer_id,
    adminId: chat.admin_id,
    createdAt: chat.created_at,
    customer: formatUser(chat.users_chats_customer_idTousers),
    admin: formatUser(chat.users_chats_admin_idTousers),
    lastMessage: lastMessage ? formatMessage(lastMessage) : null,
  };
}

function userCanAccessChat(chat, user) {
  if (!chat) return false;

  if (normalizeRole(user.role) === 'ADMIN') {
    return true;
  }

  return chat.customer_id === user.id || chat.admin_id === user.id;
}

async function listChats(jwtUser) {
  const user = await resolveCurrentUser(jwtUser);
  const chats = await chatRepository.findChatsForUser(user.id, user.role);
  return chats.map(formatChat);
}

async function openChat(jwtUser) {
  const user = await resolveCurrentUser(jwtUser);

  if (user.role === 'ADMIN') {
    throw new AppError(
      'Tài khoản admin không thể mở chat hỗ trợ. Vui lòng đăng nhập bằng tài khoản khách hàng.',
      403,
    );
  }

  const existingChat = await chatRepository.findOpenChatForCustomer(user.id);
  const chat = existingChat || await chatRepository.createChat(user.id);
  return formatChat({ ...chat, messages: [] });
}

async function listMessages(jwtUser, chatId) {
  const user = await resolveCurrentUser(jwtUser);
  const chat = await chatRepository.findChatById(chatId);

  if (!chat) {
    throw new AppError('Chat not found', 404);
  }

  if (!userCanAccessChat(chat, user)) {
    throw new AppError('Forbidden', 403);
  }

  if (user.role === 'ADMIN' && !chat.admin_id) {
    await chatRepository.assignAdmin(chatId, user.id);
  }

  const messages = await chatRepository.findMessagesByChatId(chatId);
  return messages.map(formatMessage);
}

async function sendMessage(jwtUser, chatId, payload) {
  const user = await resolveCurrentUser(jwtUser);
  const data = sendMessageDto(payload);
  const chat = await chatRepository.findChatById(chatId);

  if (!chat) {
    throw new AppError('Chat not found', 404);
  }

  if (!userCanAccessChat(chat, user)) {
    throw new AppError('Forbidden', 403);
  }

  if (user.role === 'ADMIN' && !chat.admin_id) {
    await chatRepository.assignAdmin(chatId, user.id);
  }

  const message = await chatRepository.createMessage({
    chatId,
    senderId: user.id,
    content: data.content,
  });

  return formatMessage(message);
}

module.exports = {
  listChats,
  openChat,
  listMessages,
  sendMessage,
};
