const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  getCart,
  addToCart,
  updateQuantity,
  removeFromCart,
} = require('../controllers/cart.controller');

const router = express.Router();

router.use(authenticate);

router.get('/', getCart);
router.post('/add', addToCart);
router.put('/items/:id', updateQuantity);
router.delete('/items/:id', removeFromCart);

module.exports = router;
