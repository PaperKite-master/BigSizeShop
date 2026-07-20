const crypto = require('crypto');

const HASH_FIELD = 'vnp_SecureHash';
const HASH_TYPE_FIELD = 'vnp_SecureHashType';

function encode(value) {
  return encodeURIComponent(String(value))
    .replace(/[!'()*]/g, (character) =>
      `%${character.charCodeAt(0).toString(16).toUpperCase()}`)
    .replace(/%20/g, '+');
}

function getSignableParams(params) {
  return Object.fromEntries(
    Object.entries(params)
      .filter(([key, value]) =>
        key !== HASH_FIELD &&
        key !== HASH_TYPE_FIELD &&
        value !== undefined &&
        value !== null &&
        value !== '')
      .map(([key, value]) => {
        if (Array.isArray(value) || typeof value === 'object') {
          throw new TypeError(`Invalid VNPay parameter: ${key}`);
        }
        return [key, String(value)];
      }),
  );
}

function canonicalize(params) {
  const signable = getSignableParams(params);
  return Object.keys(signable)
    .sort()
    .map((key) => `${encode(key)}=${encode(signable[key])}`)
    .join('&');
}

function createSignature(params, secret) {
  if (!secret) {
    throw new Error('VNPay hash secret is required');
  }
  return crypto.createHmac('sha512', secret).update(canonicalize(params), 'utf8').digest('hex');
}

function verifySignature(params, secret) {
  const suppliedHash = params?.[HASH_FIELD];
  if (typeof suppliedHash !== 'string' || !/^[a-fA-F0-9]{128}$/.test(suppliedHash)) {
    return false;
  }

  try {
    const expected = Buffer.from(createSignature(params, secret), 'hex');
    const supplied = Buffer.from(suppliedHash, 'hex');
    return expected.length === supplied.length && crypto.timingSafeEqual(expected, supplied);
  } catch {
    return false;
  }
}

function formatVnpayDate(date) {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map(({ type, value }) => [type, value]));
  return `${values.year}${values.month}${values.day}${values.hour}${values.minute}${values.second}`;
}

function amountToVnpay(totalPrice) {
  const value = String(totalPrice);
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(value);
  if (!match) {
    throw new Error('Order total must be a non-negative amount with at most two decimals');
  }
  const amount = (BigInt(match[1]) * 100n) + BigInt((match[2] || '').padEnd(2, '0') || '0');
  if (amount <= 0n) {
    throw new Error('Order total must be greater than zero');
  }
  return amount.toString();
}

function orderIdToTxnRef(orderId) {
  return String(orderId).replace(/-/g, '');
}

function validateCallback(params, order) {
  if (typeof params.vnp_TxnRef !== 'string' ||
      params.vnp_TxnRef.toLowerCase() !== orderIdToTxnRef(order.id).toLowerCase()) {
    return { valid: false, reason: 'ORDER' };
  }

  let expectedAmount;
  try {
    expectedAmount = amountToVnpay(order.totalPrice);
  } catch {
    return { valid: false, reason: 'AMOUNT' };
  }

  if (typeof params.vnp_Amount !== 'string' || !/^\d+$/.test(params.vnp_Amount) ||
      BigInt(params.vnp_Amount) !== BigInt(expectedAmount)) {
    return { valid: false, reason: 'AMOUNT' };
  }

  const responseCode = typeof params.vnp_ResponseCode === 'string'
    ? params.vnp_ResponseCode
    : '99';
  const successful = responseCode === '00' && params.vnp_TransactionStatus === '00';
  const transactionId = typeof params.vnp_TransactionNo === 'string'
    ? params.vnp_TransactionNo
    : null;

  if (successful && !transactionId) {
    return { valid: false, reason: 'TRANSACTION' };
  }

  return { valid: true, successful, responseCode, transactionId };
}

module.exports = {
  amountToVnpay,
  canonicalize,
  createSignature,
  formatVnpayDate,
  orderIdToTxnRef,
  validateCallback,
  verifySignature,
};
