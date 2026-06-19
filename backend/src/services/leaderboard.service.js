const prisma = require('../utils/prisma');

// Run-outs and retirements are not credited to the bowler.
function isBowlerWicket(b) {
  return b.wicket && b.wicket !== 'runOut' && b.wicket !== 'retired';
}

// Aggregates top run-scorers and wicket-takers across every device's synced
// matches. Matches are stored as JSON snapshots (SyncDocument), so we parse them
// here rather than query columns. De-duplicated by match id (a match can be
// pushed many times as it progresses — we keep the latest snapshot only).
async function globalLeaderboard(limit = 50) {
  const docs = await prisma.syncDocument.findMany({
    where: { type: 'match' },
    orderBy: { updatedAt: 'desc' },
    take: 5000,
  });

  const seen = new Set();
  const runsMap = new Map(); // name -> { name, value, matches:Set }
  const wktMap = new Map();

  const bump = (map, name, add, matchId) => {
    if (!name) return;
    const e = map.get(name) || { name, value: 0, matches: new Set() };
    e.value += add;
    e.matches.add(matchId);
    map.set(name, e);
  };

  for (const d of docs) {
    const m = d.payload;
    if (!m) continue;
    const id = d.localId || m.id;
    if (!id || seen.has(id)) continue; // latest snapshot already counted
    seen.add(id);

    const innings = Array.isArray(m.innings) ? m.innings : [];
    for (const inn of innings) {
      const balls = Array.isArray(inn.balls) ? inn.balls : [];
      for (const b of balls) {
        bump(runsMap, b.strikerName, b.runs || 0, id);
        if (isBowlerWicket(b)) bump(wktMap, b.bowlerName, 1, id);
      }
    }
  }

  const toList = (map) =>
    [...map.values()]
      .map((e) => ({ name: e.name, value: e.value, matches: e.matches.size }))
      .filter((e) => e.value > 0)
      .sort((a, b) => b.value - a.value)
      .slice(0, limit);

  return { runs: toList(runsMap), wickets: toList(wktMap) };
}

module.exports = { globalLeaderboard };
