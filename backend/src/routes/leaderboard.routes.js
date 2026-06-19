const express = require('express');
const ctrl = require('../controllers/leaderboard.controller');
const { asyncHandler } = require('../middleware/validate');

const router = express.Router();

// GET /api/leaderboard — global top run-scorers and wicket-takers.
router.get('/', asyncHandler(ctrl.global));

module.exports = router;
