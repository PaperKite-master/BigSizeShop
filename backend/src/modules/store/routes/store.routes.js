const express = require('express');
const { getAllStores, getStoreById } = require('../controllers/store.controller');

const router = express.Router();

// Public routes - no auth required
router.get('/', getAllStores);
router.get('/:id', getStoreById);

module.exports = router;
