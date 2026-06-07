const prisma = require('../utils/prisma');

// Only surface matches that have been updated recently as "live".
const LIVE_WINDOW_MS = 6 * 60 * 60 * 1000; // 6 hours

// Finished matches drop off the public Results list 24h after their last update.
const RESULTS_WINDOW_MS = 24 * 60 * 60 * 1000; // 24 hours

// --- Score helpers (mirror the Flutter model so summaries match the app) -----
function isLegal(b) {
  return b.extraType !== 'wide' && b.extraType !== 'noBall';
}
function totalRuns(b) {
  return (b.runs || 0) + (b.extraRuns || 0);
}
function inningsScore(inn) {
  const balls = (inn && inn.balls) || [];
  let runs = 0;
  let wickets = 0;
  let legal = 0;
  for (const b of balls) {
    runs += totalRuns(b);
    if (b.wicket) wickets += 1;
    if (isLegal(b)) legal += 1;
  }
  return { runs, wickets, oversText: `${Math.floor(legal / 6)}.${legal % 6}` };
}

// Compact summary for the live list.
function summarize(payload, updatedAt) {
  const innings = Array.isArray(payload.innings) ? payload.innings : [];
  const cur = innings.length ? innings[innings.length - 1] : null;
  const s = cur ? inningsScore(cur) : { runs: 0, wickets: 0, oversText: '0.0' };
  return {
    id: payload.id,
    team1: payload.team1,
    team2: payload.team2,
    overs: payload.overs,
    status: payload.status,
    ballType: payload.ballType || 'leather',
    battingTeam: cur ? cur.battingTeam : payload.battingFirst,
    runs: s.runs,
    wickets: s.wickets,
    oversText: s.oversText,
    target: cur ? cur.target || null : null,
    inningsCount: innings.length,
    resultText: payload.resultText || null,
    updatedAt,
  };
}

// In-progress matches across all devices, most recently updated first.
async function listLive() {
  const docs = await prisma.syncDocument.findMany({
    where: {
      type: 'match',
      payload: { path: ['status'], equals: 'inProgress' },
      updatedAt: { gte: new Date(Date.now() - LIVE_WINDOW_MS) },
    },
    orderBy: { updatedAt: 'desc' },
    take: 50,
  });
  return docs.map((d) => summarize(d.payload, d.updatedAt));
}

// Finished matches across all devices, most recent first. Auto-expires from the
// list 24h after the match's last update (the snapshot itself is kept in the DB).
async function listResults() {
  const docs = await prisma.syncDocument.findMany({
    where: {
      type: 'match',
      payload: { path: ['status'], equals: 'completed' },
      updatedAt: { gte: new Date(Date.now() - RESULTS_WINDOW_MS) },
    },
    orderBy: { updatedAt: 'desc' },
    take: 50,
  });
  return docs.map((d) => summarize(d.payload, d.updatedAt));
}

// The full match snapshot for a single match (live or finished), for viewing.
async function getMatch(matchId) {
  const doc = await prisma.syncDocument.findFirst({
    where: { type: 'match', localId: matchId },
    orderBy: { updatedAt: 'desc' },
  });
  if (!doc) return null;
  return { match: doc.payload, updatedAt: doc.updatedAt };
}

module.exports = { listLive, listResults, getMatch, summarize, inningsScore };
