# Cricket Scoring — Backend

Node.js + Express + Prisma + PostgreSQL API.

## Setup

```bash
npm install
cp .env.example .env        # then edit DATABASE_URL with your Postgres password
npx prisma migrate dev      # create tables
npx prisma generate         # generate client (also runs on install)
npm run dev                 # start dev server on http://localhost:3000
```

Health check: `GET http://localhost:3000/api/health`

## Scripts

| Script | What it does |
|--------|--------------|
| `npm run dev` | Start with nodemon (auto-reload) |
| `npm start` | Start once (production) |
| `npm run prisma:migrate` | Create/apply a migration |
| `npm run prisma:studio` | Open Prisma Studio (DB GUI) |

## Endpoints

See `CLAUDE.md` in the project root for the full API contract. All responses use
`{ success: true, data }` or `{ success: false, error }`.
