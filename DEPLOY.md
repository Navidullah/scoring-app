# Deployment Guide — Cricket Scoring App

The app is **offline-first**: it works fully on-device with no server. The cloud
pieces below only power **backup / sync / restore** across devices.

```
Phone app (Hive, local)  ──sync──>  Backend (Render)  ──>  PostgreSQL (Neon)
```

---

## 1. Database — Neon (done ✅)

A free Neon Postgres project is created and the connection string is in
`backend/.env` as `DATABASE_URL`. Migrations are already applied.

To re-apply migrations to a fresh Neon DB: `cd backend && npx prisma migrate deploy`.

---

## 2. Backend — Render (free)

1. Push this repo to GitHub (see below).
2. On **render.com** → **New + → Blueprint** → select your repo.
   Render reads `render.yaml` and configures the service automatically.
   (Or **New + → Web Service**, set **Root Directory** = `backend`,
   **Build** = `npm install && npx prisma generate && npx prisma migrate deploy`,
   **Start** = `node src/index.js`.)
3. In the service's **Environment**, add:
   - `DATABASE_URL` = your Neon connection string (same as in `backend/.env`).
   - `NODE_ENV` = `production`.
   (`PORT` is provided by Render automatically; the server already reads it.)
4. Deploy. When live, test: `https://<your-service>.onrender.com/api/health`
   should return `{"success":true,...}`.

> Free tier note: the service **sleeps after ~15 min idle**; the first request
> after sleeping takes ~30–60s to wake. Fine for a backup/sync app.

---

## 3. App — point it at the hosted backend

The API URL is injected at build time (never hardcoded):

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api
# or an Android App Bundle for the Play Store:
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api
```

For local development against the local backend, keep using:
`--dart-define=API_BASE_URL=http://10.0.2.2:3000/api` (Android emulator).

---

## Pushing to GitHub

```bash
git init
git add .
git commit -m "Initial commit: cricket scoring app"
git branch -M main
git remote add origin https://github.com/Navidullah/scoring-app.git
git push -u origin main
```

`.env` is gitignored — your Neon secret is **not** committed. `backend/.env.example`
documents the required variables for anyone cloning the repo.
