const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const { login, logout, me, register, saveFcmToken } = require('../controllers/auth.controller');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticate, me);
router.post('/logout', authenticate, logout);
router.post('/fcm-token', authenticate, saveFcmToken);

module.exports = router;
