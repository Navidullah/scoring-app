const express = require('express');
const ctrl = require('../controllers/team.controller');
const { asyncHandler } = require('../middleware/validate');

const router = express.Router();

router.get('/:id/players', asyncHandler(ctrl.getPlayers));

module.exports = router;
