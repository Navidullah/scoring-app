const prisma = require('../utils/prisma');

// Round-robin: every team plays every other team once.
function roundRobinPairs(teamIds) {
  const pairs = [];
  for (let i = 0; i < teamIds.length; i += 1) {
    for (let j = i + 1; j < teamIds.length; j += 1) {
      pairs.push([teamIds[i], teamIds[j]]);
    }
  }
  return pairs;
}

// Knockout: pair teams sequentially for round 1.
function knockoutPairs(teamIds) {
  const pairs = [];
  for (let i = 0; i + 1 < teamIds.length; i += 2) {
    pairs.push([teamIds[i], teamIds[i + 1]]);
  }
  return pairs;
}

async function createTournament({ name, format, deviceId, teams }) {
  return prisma.tournament.create({
    data: {
      name,
      format,
      deviceId,
      teams: {
        create: teams.map((t) => ({
          name: t.name,
          players: { create: (t.players || []).map((p) => ({ name: p })) },
        })),
      },
    },
    include: { teams: { include: { players: true } } },
  });
}

async function getTournament(id) {
  return prisma.tournament.findUnique({
    where: { id },
    include: {
      teams: { include: { players: true } },
      matches: true,
    },
  });
}

// Generate fixtures (matches) from the tournament's teams + format.
async function generateFixtures(id) {
  const tournament = await prisma.tournament.findUnique({
    where: { id },
    include: { teams: true },
  });
  if (!tournament) return null;

  const teamIds = tournament.teams.map((t) => t.id);
  const pairs =
    tournament.format === 'knockout' ? knockoutPairs(teamIds) : roundRobinPairs(teamIds);

  // Only create fixtures that don't already exist.
  const existing = await prisma.match.count({ where: { tournamentId: id } });
  if (existing === 0 && pairs.length > 0) {
    await prisma.match.createMany({
      data: pairs.map(([team1Id, team2Id]) => ({
        team1Id,
        team2Id,
        tournamentId: id,
        deviceId: tournament.deviceId,
      })),
    });
  }

  return prisma.match.findMany({
    where: { tournamentId: id },
    include: { team1: true, team2: true, winner: true },
    orderBy: { createdAt: 'asc' },
  });
}

async function updateFixture(fixtureId, data) {
  return prisma.match.update({
    where: { id: fixtureId },
    data,
    include: { team1: true, team2: true, winner: true },
  });
}

module.exports = { createTournament, getTournament, generateFixtures, updateFixture };
