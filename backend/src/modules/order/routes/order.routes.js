const express = require('express');
const { authenticate, requireAdmin } = require('../../../common/middleware/auth.middleware');
const {
  createOrder,
  cancelOrder,
  getUserOrders,
  getAdminOrders,
  updateOrderStatus,
} = require('../controllers/order.controller');

const router = express.Router();

router.use(authenticate);

router.get('/admin', requireAdmin, getAdminOrders);
router.get('/', getUserOrders);
router.post('/', createOrder);
router.patch('/:id/cancel', cancelOrder);
router.patch('/:id/status', requireAdmin, updateOrderStatus);

module.exports = router;
