const express = require('express');
const ctrl = require('../controllers/live.controller');
const { asyncHandler } = require('../middleware/validate');

const router = express.Router();

// GET /api/results — finished matches across all devices (last 24h).
router.get('/', asyncHandler(ctrl.results));

module.exports = router;
