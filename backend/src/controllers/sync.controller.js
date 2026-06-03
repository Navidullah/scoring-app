const service = require('../services/sync.service');
const { ok } = require('../utils/response');

async function sync(req, res) {
  const result = await service.bulkSync(req.body);
  ok(res, result);
}

async function pull(req, res) {
  const result = await service.pullDocuments(req.params.deviceId);
  ok(res, result);
}

module.exports = { sync, pull };
