const express = require('express');
const { authenticate } = require('../../../common/middleware/auth.middleware');
const {
  list,
  create,
  update,
  remove,
} = require('../controllers/address.controller');

const router = express.Router();

router.use(authenticate);

router.get('/', list);
router.post('/', create);
router.put('/:id', update);
router.delete('/:id', remove);

module.exports = router;
