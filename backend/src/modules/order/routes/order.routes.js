const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  createOrder,
  cancelOrder,
  getUserOrders,
  updateOrderStatus,
} = require('../controllers/order.controller');

const router = express.Router();

router.use(authenticate);

router.get('/', getUserOrders);
router.post('/', createOrder);
router.patch('/:id/cancel', cancelOrder);
router.patch('/:id/status', updateOrderStatus);

module.exports = router;
