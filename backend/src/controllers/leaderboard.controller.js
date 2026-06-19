const service = require('../services/leaderboard.service');
const { ok } = require('../utils/response');

// GET /api/leaderboard — global top run-scorers and wicket-takers across all
// devices' synced matches (public, read-only).
async function global(req, res) {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const data = await service.globalLeaderboard(limit);
  ok(res, data);
}

module.exports = { global };
