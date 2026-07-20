const { AppError } = require('../../../common/errors/app-error');
const paymentRepository = require('../repositories/payment.repository');
const {
  amountToVnpay,
  canonicalize,
  createSignature,
  formatVnpayDate,
  orderIdToTxnRef,
  validateCallback,
  verifySignature,
} = require('../helpers/vnpay.helper');

const DEFAULT_PAYMENT_URL = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function getConfig() {
  const tmnCode = process.env.VNPAY_TMN_CODE;
  const hashSecret = process.env.VNPAY_HASH_SECRET;
  const paymentUrl = process.env.VNPAY_PAYMENT_URL || DEFAULT_PAYMENT_URL;
  const publicBaseUrl = process.env.PUBLIC_BASE_URL?.replace(/\/+$/, '');

  if (!tmnCode || !hashSecret || !publicBaseUrl) {
    throw new AppError('VNPay is not configured', 503);
  }

  let paymentUrlObject;
  let publicUrlObject;
  try {
    paymentUrlObject = new URL(paymentUrl);
    publicUrlObject = new URL(publicBaseUrl);
  } catch {
    throw new AppError('VNPay URL configuration is invalid', 500);
  }
  if (paymentUrlObject.protocol !== 'https:' || publicUrlObject.protocol !== 'https:') {
    throw new AppError('VNPay URLs must use HTTPS', 500);
  }

  return {
    tmnCode,
    hashSecret,
    paymentUrl: paymentUrlObject.toString(),
    returnUrl: `${publicBaseUrl}/payments/vnpay/return`,
  };
}

function normalizeIpAddress(ipAddress) {
  const value = String(ipAddress || '127.0.0.1');
  return value.startsWith('::ffff:') ? value.slice(7) : value;
}

function txnRefToOrderId(txnRef) {
  if (typeof txnRef !== 'string' || !/^[0-9a-f]{32}$/i.test(txnRef)) {
    return null;
  }
  return [
    txnRef.slice(0, 8),
    txnRef.slice(8, 12),
    txnRef.slice(12, 16),
    txnRef.slice(16, 20),
    txnRef.slice(20),
  ].join('-').toLowerCase();
}

async function createPayment(userId, orderId, ipAddress, now = new Date()) {
  if (typeof orderId !== 'string' || !UUID_PATTERN.test(orderId)) {
    throw new AppError('A valid orderId is required', 400);
  }

  const order = await paymentRepository.findOrderByIdAndUserId(orderId, userId);
  if (!order) {
    throw new AppError('Order not found', 404);
  }
  if (order.paymentMethod !== 'BANK') {
    throw new AppError('VNPay is only available for BANK orders', 400);
  }
  if (order.paymentStatus !== 'UNPAID') {
    throw new AppError('Order is not awaiting payment', 409);
  }

  const config = getConfig();
  const expiresAt = new Date(now.getTime() + (15 * 60 * 1000));
  const params = {
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: config.tmnCode,
    vnp_Amount: amountToVnpay(order.totalPrice),
    vnp_CurrCode: 'VND',
    vnp_TxnRef: orderIdToTxnRef(order.id),
    vnp_OrderInfo: `Thanh toan don hang ${order.id}`,
    vnp_OrderType: 'other',
    vnp_Locale: 'vn',
    vnp_ReturnUrl: config.returnUrl,
    vnp_IpAddr: normalizeIpAddress(ipAddress),
    vnp_CreateDate: formatVnpayDate(now),
    vnp_ExpireDate: formatVnpayDate(expiresAt),
  };
  const signature = createSignature(params, config.hashSecret);
  const separator = config.paymentUrl.includes('?') ? '&' : '?';
  const paymentUrl = `${config.paymentUrl}${separator}${canonicalize(params)}` +
    `&vnp_SecureHashType=HmacSHA512&vnp_SecureHash=${signature}`;

  return { paymentUrl, orderId: order.id };
}

async function processCallback(params) {
  let config;
  try {
    config = getConfig();
  } catch {
    return { state: 'CONFIGURATION_ERROR', responseCode: '99' };
  }

  if (!verifySignature(params, config.hashSecret)) {
    return { state: 'INVALID_CHECKSUM', responseCode: '97' };
  }

  const orderId = txnRefToOrderId(params.vnp_TxnRef);
  if (!orderId || !UUID_PATTERN.test(orderId)) {
    return { state: 'ORDER_NOT_FOUND', responseCode: '01' };
  }

  const order = await paymentRepository.findOrderById(orderId);
  if (!order || order.paymentMethod !== 'BANK') {
    return { state: 'ORDER_NOT_FOUND', responseCode: '01' };
  }

  const validation = validateCallback(params, order);
  if (!validation.valid) {
    return {
      state: validation.reason === 'AMOUNT' ? 'INVALID_AMOUNT' : 'INVALID_CALLBACK',
      responseCode: validation.reason === 'AMOUNT' ? '04' : '99',
      orderId: order.id,
    };
  }

  if (!validation.successful) {
    return {
      state: 'DECLINED',
      responseCode: validation.responseCode,
      orderId: order.id,
    };
  }

  try {
    const confirmation = await paymentRepository.confirmPayment(
      order.id,
      validation.transactionId,
    );
    return {
      state: confirmation.state,
      responseCode: confirmation.state === 'CONFIRMED' ? '00' : '02',
      orderId: order.id,
    };
  } catch (error) {
    if (error?.code === 'P2002') {
      return { state: 'CONFLICT', responseCode: '02', orderId: order.id };
    }
    throw error;
  }
}

async function getPaymentStatus(userId, orderId) {
  if (typeof orderId !== 'string' || !UUID_PATTERN.test(orderId)) {
    throw new AppError('A valid orderId is required', 400);
  }
  const order = await paymentRepository.findOrderByIdAndUserId(orderId, userId);
  if (!order) {
    throw new AppError('Order not found', 404);
  }
  return {
    orderId: order.id,
    paymentMethod: order.paymentMethod,
    paymentStatus: order.paymentStatus,
    paymentTransactionId: order.paymentTransactionId,
    paidAt: order.paidAt,
  };
}

module.exports = {
  createPayment,
  getPaymentStatus,
  processCallback,
};
