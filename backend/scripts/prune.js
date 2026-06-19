#!/usr/bin/env node
/**
 * Admin-only cleanup for the synced match/tournament snapshots (SyncDocument).
 *
 * This is NOT exposed over the API — it runs from a command line and needs the
 * database credentials (DATABASE_URL in backend/.env, or Render's shell), so
 * only the project owner can run it. App users cannot trigger it.
 *
 * SAFETY: dry-run by default. It prints what WOULD be deleted and changes
 * nothing unless you pass --yes. It also refuses to delete everything unless
 * you explicitly pass --all.
 *
 * Examples:
 *   node scripts/prune.js --older-than=30d --status=completed         # preview
 *   node scripts/prune.js --older-than=30d --status=completed --yes   # delete
 *   node scripts/prune.js --match=<match-uuid> --yes
 *   node scripts/prune.js --device=<deviceId> --yes
 *   node scripts/prune.js --all --yes                                 # wipe all
 *
 * Flags:
 *   --older-than=<N><d|h|w>  only docs not updated in the last N days/hours/weeks
 *   --status=<status>        match status, e.g. completed | inProgress
 *   --type=<match|tournament>
 *   --device=<deviceId>
 *   --match=<localId>        a single match/tournament by its id
 *   --all                    no filters (required to target the whole table)
 *   --yes                    actually delete (otherwise dry-run preview only)
 *
 * Remember: a phone that still holds a match locally will re-upload it on its
 * next sync, so also delete it on the device if you want it gone for good.
 */
require('dotenv').config();
const prisma = require('../src/utils/prisma');

function parseArgs(argv) {
  const args = {};
  for (const a of argv.slice(2)) {
    const m = /^--([^=]+)(?:=(.*))?$/.exec(a);
    if (!m) continue;
    args[m[1]] = m[2] === undefined ? true : m[2];
  }
  return args;
}

function ageToMs(s) {
  const m = /^(\d+)([dhw])$/.exec(String(s).trim());
  if (!m) throw new Error(`--older-than must look like 30d, 12h, or 2w (got "${s}")`);
  const n = Number(m[1]);
  const unit = { h: 3600e3, d: 86400e3, w: 7 * 86400e3 }[m[2]];
  return n * unit;
}

function buildWhere(args) {
  const where = {};
  if (args.type) where.type = String(args.type);
  if (args.device) where.deviceId = String(args.device);
  if (args.match) where.localId = String(args.match);
  if (args.status) where.payload = { path: ['status'], equals: String(args.status) };
  if (args['older-than']) {
    where.updatedAt = { lt: new Date(Date.now() - ageToMs(args['older-than'])) };
  }
  return where;
}

function describe(doc) {
  const p = doc.payload || {};
  const who = p.team1 && p.team2 ? `${p.team1} vs ${p.team2}` : p.name || '(unknown)';
  const status = p.status ? ` [${p.status}]` : '';
  const when = doc.updatedAt ? doc.updatedAt.toISOString().slice(0, 10) : '?';
  return `${doc.type} ${who}${status} — updated ${when} — id ${doc.localId}`;
}

async function main() {
  const args = parseArgs(process.argv);
  const where = buildWhere(args);

  const hasFilter = Object.keys(where).length > 0;
  if (!hasFilter && !args.all) {
    console.error(
      'Refusing to run with no filters. Add a filter (e.g. --older-than=30d, ' +
        '--status=completed, --device=…, --match=…) or pass --all to target every row.',
    );
    process.exit(1);
  }

  const total = await prisma.syncDocument.count({ where });
  if (total === 0) {
    console.log('Nothing matches those filters. Nothing to delete.');
    return;
  }

  const sample = await prisma.syncDocument.findMany({
    where,
    orderBy: { updatedAt: 'desc' },
    take: 10,
  });

  console.log(`\nMatched ${total} document${total === 1 ? '' : 's'}:`);
  for (const d of sample) console.log('  - ' + describe(d));
  if (total > sample.length) console.log(`  …and ${total - sample.length} more`);

  if (!args.yes) {
    console.log(
      `\nDRY RUN — nothing deleted. Re-run with --yes to delete these ${total} document${total === 1 ? '' : 's'}.`,
    );
    return;
  }

  const result = await prisma.syncDocument.deleteMany({ where });
  console.log(`\nDeleted ${result.count} document${result.count === 1 ? '' : 's'}.`);
  console.log(
    'Note: a device that still holds these matches locally will re-upload them on its next sync.',
  );
}

main()
  .catch((e) => {
    console.error('Prune failed:', e.message);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
