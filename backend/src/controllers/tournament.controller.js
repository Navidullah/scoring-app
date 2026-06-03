const service = require('../services/tournament.service');
const { ok, fail } = require('../utils/response');

async function create(req, res) {
  const tournament = await service.createTournament(req.body);
  ok(res, tournament, 201);
}

async function get(req, res) {
  const tournament = await service.getTournament(req.params.id);
  if (!tournament) return fail(res, 'Tournament not found', 404);
  ok(res, tournament);
}

async function fixtures(req, res) {
  const list = await service.generateFixtures(req.params.id);
  if (list === null) return fail(res, 'Tournament not found', 404);
  ok(res, list);
}

async function updateFixture(req, res) {
  const updated = await service.updateFixture(req.params.fixtureId, req.body);
  ok(res, updated);
}

module.exports = { create, get, fixtures, updateFixture };
