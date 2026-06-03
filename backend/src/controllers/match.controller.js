const service = require('../services/match.service');
const { ok, fail } = require('../utils/response');

async function create(req, res) {
  const match = await service.createMatch(req.body);
  ok(res, match, 201);
}

async function get(req, res) {
  const match = await service.getMatch(req.params.id);
  if (!match) return fail(res, 'Match not found', 404);
  ok(res, match);
}

async function addBall(req, res) {
  const ball = await service.addBall(req.params.id, req.body);
  ok(res, ball, 201);
}

async function undoLast(req, res) {
  const removed = await service.undoLastBall(req.params.id);
  if (!removed) return fail(res, 'No balls to undo', 404);
  ok(res, removed);
}

async function complete(req, res) {
  const match = await service.completeMatch(req.params.id, req.body);
  ok(res, match);
}

module.exports = { create, get, addBall, undoLast, complete };
