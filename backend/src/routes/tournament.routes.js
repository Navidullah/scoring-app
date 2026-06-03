const express = require('express');
const ctrl = require('../controllers/tournament.controller');
const { validate, asyncHandler } = require('../middleware/validate');
const { createTournament, updateFixture } = require('../validators/schemas');

const router = express.Router();

router.post('/', validate(createTournament), asyncHandler(ctrl.create));
router.get('/:id', asyncHandler(ctrl.get));
router.get('/:id/fixtures', asyncHandler(ctrl.fixtures));
router.put('/:id/fixture/:fixtureId', validate(updateFixture), asyncHandler(ctrl.updateFixture));

module.exports = router;
