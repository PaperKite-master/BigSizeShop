const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  list,
  placeOrder,
} = require('../controllers/order.controller');

const router = express.Router();

router.use(authenticate);

router.get('/', list);
router.post('/', placeOrder);

module.exports = router;
