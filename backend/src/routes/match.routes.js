const express = require('express');
const ctrl = require('../controllers/match.controller');
const { validate, asyncHandler } = require('../middleware/validate');
const { createMatch, addBall, completeMatch } = require('../validators/schemas');

const router = express.Router();

router.post('/', validate(createMatch), asyncHandler(ctrl.create));
router.get('/:id', asyncHandler(ctrl.get));
router.post('/:id/balls', validate(addBall), asyncHandler(ctrl.addBall));
router.delete('/:id/balls/last', asyncHandler(ctrl.undoLast));
router.put('/:id/complete', validate(completeMatch), asyncHandler(ctrl.complete));

module.exports = router;
