const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  listAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
} = require('../controllers/address.controller');

const router = express.Router();

router.use(authenticate);
router.get('/', listAddresses);
router.post('/', createAddress);
router.put('/:id', updateAddress);
router.delete('/:id', deleteAddress);

module.exports = router;
