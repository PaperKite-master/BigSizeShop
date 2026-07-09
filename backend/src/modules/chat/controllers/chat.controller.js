const { asyncHandler } = require('../../../common/utils/async-handler');
const chatService = require('../services/chat.service');

const listChats = asyncHandler(async (req, res) => {
  const data = await chatService.listChats(req.user);

  res.json({
    message: 'Chats fetched successfully',
    data,
  });
});

const openChat = asyncHandler(async (req, res) => {
  const data = await chatService.openChat(req.user);

  res.status(201).json({
    message: 'Chat opened successfully',
    data,
  });
});

const listMessages = asyncHandler(async (req, res) => {
  const data = await chatService.listMessages(req.user, req.params.chatId);

  res.json({
    message: 'Messages fetched successfully',
    data,
  });
});

const sendMessage = asyncHandler(async (req, res) => {
  const data = await chatService.sendMessage(req.user, req.params.chatId, req.body);

  res.status(201).json({
    message: 'Message sent successfully',
    data,
  });
});

module.exports = {
  listChats,
  openChat,
  listMessages,
  sendMessage,
};
