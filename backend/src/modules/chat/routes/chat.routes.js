const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  listChats,
  openChat,
  listMessages,
  sendMessage,
} = require('../controllers/chat.controller');

const router = express.Router();

router.use(authenticate);

router.get('/', listChats);
router.post('/', openChat);
router.get('/:chatId/messages', listMessages);
router.post('/:chatId/messages', sendMessage);

module.exports = router;
