const express = require('express');
const { authenticate, requireAdmin } = require('../../../common/middleware/auth.middleware');
const { sendBroadcast } = require('../controllers/notification.controller');

const router = express.Router();

// Broadcast route - strictly admin only
router.post('/broadcast', authenticate, requireAdmin, sendBroadcast);

module.exports = router;
