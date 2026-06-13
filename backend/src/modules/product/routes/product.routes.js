const express = require('express');
const { authenticate, requireAdmin } = require('../../../common/middleware/auth.middleware');
const {
  create,
  filter,
  getById,
  list,
  remove,
  search,
  update,
} = require('../controllers/product.controller');

const router = express.Router();

router.get('/search', search);
router.get('/filter', filter);
router.get('/', list);
router.get('/:id', getById);
router.post('/', authenticate, requireAdmin, create);
router.put('/:id', authenticate, requireAdmin, update);
router.delete('/:id', authenticate, requireAdmin, remove);

module.exports = router;
