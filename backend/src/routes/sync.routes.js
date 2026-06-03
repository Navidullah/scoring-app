const express = require('express');
const ctrl = require('../controllers/sync.controller');
const { validate, asyncHandler } = require('../middleware/validate');
const { syncPayload } = require('../validators/schemas');

const router = express.Router();

router.post('/', validate(syncPayload), asyncHandler(ctrl.sync));
router.get('/:deviceId', asyncHandler(ctrl.pull));

module.exports = router;
