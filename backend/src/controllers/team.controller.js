const service = require('../services/team.service');
const { ok, fail } = require('../utils/response');

async function getPlayers(req, res) {
  const players = await service.getPlayers(req.params.id);
  if (players === null) return fail(res, 'Team not found', 404);
  ok(res, players);
}

module.exports = { getPlayers };
