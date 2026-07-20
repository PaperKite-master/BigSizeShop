const { asyncHandler } = require('../../../common/utils/async-handler');
const paymentService = require('../services/payment.service');

const createVnpayPayment = asyncHandler(async (req, res) => {
  const result = await paymentService.createPayment(
    req.user.id,
    req.body?.orderId,
    req.ip,
  );
  res.json({
    message: 'VNPay payment URL created successfully',
    data: result,
  });
});

function makeDeepLink(result) {
  const configured = process.env.APP_DEEP_LINK || 'bigsize-shop://payment-result';
  let url;
  try {
    url = new URL(configured);
  } catch {
    url = new URL('bigsize-shop://payment-result');
  }

  if (result.orderId) {
    url.searchParams.set('orderId', result.orderId);
  }
  const success = result.state === 'CONFIRMED' || result.state === 'ALREADY_CONFIRMED';
  url.searchParams.set('success', String(success));
  url.searchParams.set(
    'responseCode',
    success ? '00' : (result.responseCode || '99'),
  );
  return url.toString();
}

const handleVnpayReturn = async (req, res) => {
  let result;
  try {
    result = await paymentService.processCallback(req.query);
  } catch {
    result = { state: 'PROCESSING_ERROR', responseCode: '99' };
  }
  res.redirect(302, makeDeepLink(result));
};

const IPN_RESPONSES = {
  CONFIRMED: { RspCode: '00', Message: 'Confirm Success' },
  DECLINED: { RspCode: '00', Message: 'Confirm Success' },
  INVALID_CHECKSUM: { RspCode: '97', Message: 'Invalid Checksum' },
  ORDER_NOT_FOUND: { RspCode: '01', Message: 'Order not found' },
  INVALID_AMOUNT: { RspCode: '04', Message: 'Invalid amount' },
  ALREADY_CONFIRMED: { RspCode: '02', Message: 'Order already confirmed' },
  CONFLICT: { RspCode: '02', Message: 'Order already confirmed' },
};

const handleVnpayIpn = async (req, res) => {
  try {
    const result = await paymentService.processCallback(req.query);
    res.json(IPN_RESPONSES[result.state] || {
      RspCode: '99',
      Message: 'Invalid request',
    });
  } catch {
    res.json({ RspCode: '99', Message: 'Unknown error' });
  }
};

const getOrderPaymentStatus = asyncHandler(async (req, res) => {
  const result = await paymentService.getPaymentStatus(req.user.id, req.params.orderId);
  res.json({
    message: 'Payment status retrieved successfully',
    data: result,
  });
});

module.exports = {
  createVnpayPayment,
  getOrderPaymentStatus,
  handleVnpayIpn,
  handleVnpayReturn,
};
