const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const { login, logout, me, register } = require('../controllers/auth.controller');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticate, me);
router.post('/logout', authenticate, logout);

module.exports = router;
