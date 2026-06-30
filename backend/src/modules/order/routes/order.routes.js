const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  createOrder,
  cancelOrder,
} = require('../controllers/order.controller');

const router = express.Router();

router.use(authenticate);

router.post('/', createOrder);
router.patch('/:id/cancel', cancelOrder);

module.exports = router;
