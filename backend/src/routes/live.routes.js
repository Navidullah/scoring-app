const express = require('express');
const ctrl = require('../controllers/live.controller');
const { asyncHandler } = require('../middleware/validate');

const router = express.Router();

router.get('/', asyncHandler(ctrl.list));
router.get('/:id', asyncHandler(ctrl.get));

module.exports = router;
