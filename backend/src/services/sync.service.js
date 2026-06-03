const prisma = require('../utils/prisma');

// Push: upsert each local match/tournament snapshot keyed by (device, type, id).
// Local always wins, so we just overwrite the stored payload with what's sent.
async function bulkSync({ deviceId, matches, tournaments }) {
  await prisma.device.upsert({
    where: { deviceId },
    create: { deviceId },
    update: {},
  });

  const upsertDoc = (type, doc) =>
    prisma.syncDocument.upsert({
      where: { deviceId_type_localId: { deviceId, type, localId: doc.id } },
      create: { deviceId, type, localId: doc.id, payload: doc },
      update: { payload: doc },
    });

  await Promise.all([
    ...matches.map((m) => upsertDoc('match', m)),
    ...tournaments.map((t) => upsertDoc('tournament', t)),
  ]);

  return {
    deviceId,
    pushed: { matches: matches.length, tournaments: tournaments.length },
    syncedAt: new Date().toISOString(),
  };
}

// Pull: return every stored document for a device, so a (re)installed app can
// restore its data.
async function pullDocuments(deviceId) {
  const docs = await prisma.syncDocument.findMany({
    where: { deviceId },
    orderBy: { updatedAt: 'desc' },
  });
  return {
    deviceId,
    matches: docs.filter((d) => d.type === 'match').map((d) => d.payload),
    tournaments: docs.filter((d) => d.type === 'tournament').map((d) => d.payload),
  };
}

module.exports = { bulkSync, pullDocuments };
