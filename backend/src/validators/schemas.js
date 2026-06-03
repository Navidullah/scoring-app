const { z } = require('zod');

const createTournament = z.object({
  name: z.string().min(1).max(100),
  format: z.enum(['round_robin', 'knockout']).default('round_robin'),
  deviceId: z.string().uuid().optional(),
  teams: z
    .array(
      z.object({
        name: z.string().min(1).max(100),
        players: z.array(z.string().min(1)).optional().default([]),
      })
    )
    .optional()
    .default([]),
});

const updateFixture = z.object({
  winnerId: z.string().uuid().optional(),
  status: z.enum(['scheduled', 'in_progress', 'completed', 'abandoned']).optional(),
});

const createMatch = z.object({
  team1Id: z.string().uuid(),
  team2Id: z.string().uuid(),
  tournamentId: z.string().uuid().optional(),
  deviceId: z.string().uuid().optional(),
  overs: z.number().int().positive().max(100).default(20),
});

const addBall = z.object({
  inningsId: z.string().uuid(),
  overNo: z.number().int().min(0),
  ballNo: z.number().int().min(1).max(6),
  runs: z.number().int().min(0).max(7).default(0),
  extraType: z.enum(['wide', 'no_ball', 'bye', 'leg_bye']).optional(),
  extraRuns: z.number().int().min(0).default(0),
  wicket: z
    .enum(['bowled', 'caught', 'lbw', 'run_out', 'stumped', 'hit_wicket', 'retired'])
    .optional(),
  batsmanId: z.string().uuid(),
  bowlerId: z.string().uuid(),
});

const completeMatch = z.object({
  winnerId: z.string().uuid().optional(),
});

const syncPayload = z.object({
  deviceId: z.string().min(1),
  matches: z.array(z.object({ id: z.string() }).passthrough()).optional().default([]),
  tournaments: z.array(z.object({ id: z.string() }).passthrough()).optional().default([]),
});

module.exports = {
  createTournament,
  updateFixture,
  createMatch,
  addBall,
  completeMatch,
  syncPayload,
};
