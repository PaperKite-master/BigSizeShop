const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  getCart,
  addItem,
  updateItemQuantity,
  removeItem,
} = require('../controllers/cart.controller');

const router = express.Router();

// All cart routes require authentication
router.use(authenticate);

router.get('/', getCart);
router.post('/', addItem);
router.put('/:id', updateItemQuantity);
router.delete('/:id', removeItem);

module.exports = router;
