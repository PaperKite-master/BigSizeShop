const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  createVnpayPayment,
  getOrderPaymentStatus,
  handleVnpayIpn,
  handleVnpayReturn,
} = require('../controllers/payment.controller');

const router = express.Router();

router.get('/vnpay/return', handleVnpayReturn);
router.get('/vnpay/ipn', handleVnpayIpn);
router.post('/vnpay/create', authenticate, createVnpayPayment);
router.get('/orders/:orderId/status', authenticate, getOrderPaymentStatus);

module.exports = router;
