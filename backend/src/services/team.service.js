const prisma = require('../utils/prisma');

async function getPlayers(teamId) {
  const team = await prisma.team.findUnique({
    where: { id: teamId },
    include: { players: { orderBy: { createdAt: 'asc' } } },
  });
  return team ? team.players : null;
}

module.exports = { getPlayers };
