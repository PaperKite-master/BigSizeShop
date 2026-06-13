const express = require('express');
const { authenticate, requireAdmin } = require('../../../common/middleware/auth.middleware');
const { create, list, remove, update } = require('../controllers/category.controller');

const router = express.Router();

router.get('/', list);
router.post('/', authenticate, requireAdmin, create);
router.put('/:id', authenticate, requireAdmin, update);
router.delete('/:id', authenticate, requireAdmin, remove);

module.exports = router;
