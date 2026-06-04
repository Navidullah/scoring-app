const service = require('../services/live.service');
const { ok, fail } = require('../utils/response');

// GET /api/live — list of in-progress matches (public).
async function list(req, res) {
  const matches = await service.listLive();
  ok(res, matches);
}

// GET /api/live/:id — full snapshot of a single match (public, read-only).
async function get(req, res) {
  const result = await service.getMatch(req.params.id);
  if (!result) return fail(res, 'Match not found', 404);
  ok(res, result.match);
}

module.exports = { list, get };
