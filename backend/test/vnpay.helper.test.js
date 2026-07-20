const test = require('node:test');
const assert = require('node:assert/strict');
const {
  canonicalize,
  createSignature,
  validateCallback,
  verifySignature,
} = require('../src/modules/payment/helpers/vnpay.helper');

test('canonicalization and HMAC SHA512 signature are deterministic', () => {
  const params = {
    vnp_TxnRef: 'order-123',
    vnp_OrderInfo: 'Thanh toan don hang order-123',
    vnp_Amount: '1250000',
    vnp_TmnCode: 'DEMO',
  };

  assert.equal(
    canonicalize(params),
    'vnp_Amount=1250000&vnp_OrderInfo=Thanh+toan+don+hang+order-123' +
      '&vnp_TmnCode=DEMO&vnp_TxnRef=order-123',
  );
  assert.equal(
    createSignature(params, 'test-secret'),
    '3df9835ca6ee741ba9d47caa32ac3e6b3cf6b3871f80fbaf36cd2035e1ffee4e' +
      '6513f869c55a7f979b5656481e964a062b7a2ede3c1159929099cc024855130d',
  );
});

test('signature verification strips secure hash fields and rejects tampering', () => {
  const params = {
    vnp_Amount: '10000',
    vnp_TxnRef: '9b2d8788-7232-4b65-856a-b8c2693fd5a2',
  };
  const signed = {
    ...params,
    vnp_SecureHashType: 'HmacSHA512',
    vnp_SecureHash: createSignature(params, 'secret'),
  };

  assert.equal(verifySignature(signed, 'secret'), true);
  assert.equal(verifySignature({ ...signed, vnp_Amount: '20000' }, 'secret'), false);
  assert.equal(verifySignature({ ...signed, vnp_SecureHash: ['bad'] }, 'secret'), false);
});

test('callback validation compares server amount and success statuses', () => {
  const order = {
    id: '9b2d8788-7232-4b65-856a-b8c2693fd5a2',
    totalPrice: '12500.50',
  };
  const valid = validateCallback({
    vnp_TxnRef: '9b2d878872324b65856ab8c2693fd5a2',
    vnp_Amount: '1250050',
    vnp_ResponseCode: '00',
    vnp_TransactionStatus: '00',
    vnp_TransactionNo: '14422560',
  }, order);

  assert.deepEqual(valid, {
    valid: true,
    successful: true,
    responseCode: '00',
    transactionId: '14422560',
  });
  assert.deepEqual(
    validateCallback({
      vnp_TxnRef: '9b2d878872324b65856ab8c2693fd5a2',
      vnp_Amount: '1250051',
      vnp_ResponseCode: '00',
      vnp_TransactionStatus: '00',
      vnp_TransactionNo: '14422560',
    }, order),
    { valid: false, reason: 'AMOUNT' },
  );
});
