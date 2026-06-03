const prisma = require('../utils/prisma');

async function createMatch({ team1Id, team2Id, tournamentId, deviceId, overs }) {
  return prisma.match.create({
    data: {
      team1Id,
      team2Id,
      tournamentId,
      deviceId,
      overs,
      status: 'in_progress',
      // Start with the first innings for team1 batting.
      innings: { create: { inningsNo: 1, battingTeamId: team1Id } },
    },
    include: { innings: true, team1: true, team2: true },
  });
}

async function getMatch(id) {
  return prisma.match.findUnique({
    where: { id },
    include: {
      team1: { include: { players: true } },
      team2: { include: { players: true } },
      winner: true,
      innings: {
        include: {
          battingTeam: true,
          balls: { orderBy: [{ overNo: 'asc' }, { ballNo: 'asc' }] },
        },
      },
      playerStats: { include: { player: true } },
    },
  });
}

// Total runs counted toward the batting side for a single ball.
function ballRunTotal(ball) {
  return (ball.runs || 0) + (ball.extraRuns || 0);
}

// Add a ball and incrementally update the batsman/bowler match stats.
async function addBall(matchId, ball) {
  return prisma.$transaction(async (tx) => {
    const created = await tx.ball.create({ data: { ...ball } });

    const isExtraBall = ball.extraType === 'wide' || ball.extraType === 'no_ball';
    const runTotal = ballRunTotal(ball);

    // Batsman stats: runs off the bat + a legal ball faced (not on wide).
    await tx.playerMatchStat.upsert({
      where: { matchId_playerId: { matchId, playerId: ball.batsmanId } },
      create: {
        matchId,
        playerId: ball.batsmanId,
        runs: ball.runs || 0,
        balls: ball.extraType === 'wide' ? 0 : 1,
        fours: ball.runs === 4 ? 1 : 0,
        sixes: ball.runs === 6 ? 1 : 0,
      },
      update: {
        runs: { increment: ball.runs || 0 },
        balls: { increment: ball.extraType === 'wide' ? 0 : 1 },
        fours: { increment: ball.runs === 4 ? 1 : 0 },
        sixes: { increment: ball.runs === 6 ? 1 : 0 },
      },
    });

    // Bowler stats: concedes runs; takes a wicket unless it's a run-out.
    const wicketCredit = ball.wicket && ball.wicket !== 'run_out' ? 1 : 0;
    await tx.playerMatchStat.upsert({
      where: { matchId_playerId: { matchId, playerId: ball.bowlerId } },
      create: {
        matchId,
        playerId: ball.bowlerId,
        runsConceded: runTotal,
        wickets: wicketCredit,
        oversBowled: isExtraBall ? 0 : 0.1,
      },
      update: {
        runsConceded: { increment: runTotal },
        wickets: { increment: wicketCredit },
        oversBowled: { increment: isExtraBall ? 0 : 0.1 },
      },
    });

    return created;
  });
}

// Undo the most recently added ball in a match (across all innings).
async function undoLastBall(matchId) {
  const last = await prisma.ball.findFirst({
    where: { innings: { matchId } },
    orderBy: { createdAt: 'desc' },
  });
  if (!last) return null;

  return prisma.$transaction(async (tx) => {
    const isExtraBall = last.extraType === 'wide' || last.extraType === 'no_ball';
    const runTotal = ballRunTotal(last);
    const wicketCredit = last.wicket && last.wicket !== 'run_out' ? 1 : 0;

    await tx.playerMatchStat.update({
      where: { matchId_playerId: { matchId, playerId: last.batsmanId } },
      data: {
        runs: { decrement: last.runs || 0 },
        balls: { decrement: last.extraType === 'wide' ? 0 : 1 },
        fours: { decrement: last.runs === 4 ? 1 : 0 },
        sixes: { decrement: last.runs === 6 ? 1 : 0 },
      },
    });

    await tx.playerMatchStat.update({
      where: { matchId_playerId: { matchId, playerId: last.bowlerId } },
      data: {
        runsConceded: { decrement: runTotal },
        wickets: { decrement: wicketCredit },
        oversBowled: { decrement: isExtraBall ? 0 : 0.1 },
      },
    });

    await tx.ball.delete({ where: { id: last.id } });
    return last;
  });
}

async function completeMatch(matchId, { winnerId }) {
  return prisma.match.update({
    where: { id: matchId },
    data: { status: 'completed', winnerId: winnerId || null },
    include: { team1: true, team2: true, winner: true },
  });
}

module.exports = { createMatch, getMatch, addBall, undoLastBall, completeMatch };
