# Cricket Scoring App — CLAUDE.md

This file provides full project context for Claude Code (VS Code). Read this before making any changes.

---

## Project Overview

**App Name:** Cricket Scoring App
**Type:** Full-stack mobile app (Flutter + Node.js + PostgreSQL)
**Goal:** A production-ready cricket scoring app for local/casual/tournament matches. Works offline, syncs to cloud when online.
**Target Market:** India, Pakistan, Bangladesh
**Play Store:** Yes — must be Play Store ready

---

## Tech Stack

### Mobile (Flutter)

- **Language:** Dart
- **Flutter SDK:** Latest stable
- **State Management:** Riverpod (flutter_riverpod)
- **Local Database:** Hive (offline storage)
- **HTTP Client:** Dio
- **Navigation:** GoRouter
- **UI:** Material 3 (custom theme)
- **Sync:** Background sync queue (local-first, sync on connectivity)

### Backend (Node.js)

- **Runtime:** Node.js (LTS)
- **Framework:** Express.js
- **ORM:** Prisma
- **Database:** PostgreSQL
- **Auth:** None (anonymous device ID based)
- **API Style:** REST

### DevOps / Hosting

- **Backend Hosting:** Railway or Render (free tier)
- **Database Hosting:** Railway PostgreSQL or Supabase
- **Environment:** .env files (never commit)

---

## Project Structure

```
scoring_app/
├── app/                        # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart            # App root, theme, router
│   │   ├── core/
│   │   │   ├── constants/      # App-wide constants
│   │   │   ├── theme/          # Colors, typography, theme data
│   │   │   ├── utils/          # Helper functions
│   │   │   └── extensions/     # Dart extensions
│   │   ├── data/
│   │   │   ├── local/          # Hive models and adapters
│   │   │   ├── remote/         # Dio API clients
│   │   │   └── repositories/   # Repository pattern (local + remote)
│   │   ├── domain/
│   │   │   ├── models/         # Pure Dart models
│   │   │   └── enums/          # App enums (WicketType, ExtraType, etc.)
│   │   ├── features/
│   │   │   ├── home/           # Home screen
│   │   │   ├── match/          # Match setup, live scoring, scorecard
│   │   │   ├── tournament/     # Tournament creation, fixtures, leaderboard
│   │   │   ├── history/        # Past matches
│   │   │   └── settings/       # App settings
│   │   └── shared/
│   │       ├── widgets/        # Reusable widgets
│   │       └── providers/      # Shared Riverpod providers
│   ├── assets/
│   │   ├── images/
│   │   └── fonts/
│   ├── test/
│   └── pubspec.yaml
│
├── backend/                    # Node.js API server
│   ├── src/
│   │   ├── index.js            # Entry point
│   │   ├── routes/             # Express routes
│   │   ├── controllers/        # Route handlers
│   │   ├── middleware/         # Auth, error handling, validation
│   │   ├── services/           # Business logic
│   │   └── utils/              # Helpers
│   ├── prisma/
│   │   ├── schema.prisma       # Database schema
│   │   └── migrations/         # Auto-generated migrations
│   ├── .env                    # Environment variables (never commit)
│   ├── .env.example            # Template for env vars
│   └── package.json
│
└── CLAUDE.md                   # This file
```

---

## Core Features (V1)

1. **Live Ball-by-Ball Scoring**
   - Record each ball: runs (0-6), wickets, extras (wide, no-ball, bye, leg-bye)
   - Current over display, run rate, required run rate
   - Undo last ball

2. **Individual Player Stats**
   - Batting: runs, balls faced, 4s, 6s, strike rate, dismissal type
   - Bowling: overs, maidens, runs, wickets, economy rate

3. **Match History**
   - Full scorecards for past matches
   - Winner, match summary, player of the match

4. **Tournament Mode**
   - Create tournament with team names and player lists
   - Round-robin or knockout format
   - Auto-generate fixtures
   - Points table / leaderboard

---

## Data Models (Key Entities)

```
Device         → deviceId (UUID), createdAt
Tournament     → id, name, format (round_robin/knockout), teams[], status
Team           → id, name, players[], tournamentId?
Player         → id, name, teamId
Match          → id, team1Id, team2Id, tournamentId?, overs, status, winnerId?
Innings        → id, matchId, battingTeamId, balls[]
Ball           → id, inningsId, overNo, ballNo, runs, extras, wicket?, batsmanId, bowlerId
PlayerMatchStat → id, matchId, playerId, runs, balls, fours, sixes, wickets, oversBowled, runsConceded
```

---

## API Endpoints (Backend)

```
POST   /api/tournaments          # Create tournament
GET    /api/tournaments/:id      # Get tournament details
GET    /api/tournaments/:id/fixtures  # Get fixtures
PUT    /api/tournaments/:id/fixture/:fixtureId  # Update fixture result

POST   /api/matches              # Create match
GET    /api/matches/:id          # Get match with scorecard
POST   /api/matches/:id/balls    # Add ball (scoring)
DELETE /api/matches/:id/balls/last  # Undo last ball
PUT    /api/matches/:id/complete # Complete match

GET    /api/teams/:id/players    # Get team players
POST   /api/sync                 # Bulk sync offline data
```

---

## Offline-First Sync Strategy

- All data is written to **Hive** (local DB) first
- Every write is added to a **sync queue** (also in Hive)
- When internet is available, queue items are sent to the backend
- Backend returns server IDs which update local records
- Conflicts: **local always wins** for in-progress matches

---

## Coding Conventions

### Flutter / Dart

- Use `const` constructors wherever possible
- All Riverpod providers in `*_provider.dart` files
- Repository pattern: UI never calls API directly
- Models are immutable (use `copyWith`)
- File names: `snake_case.dart`
- Class names: `PascalCase`
- No hardcoded strings — use constants

### Node.js / Backend

- All routes in `routes/` — thin, just calls controller
- Business logic only in `services/`
- Always validate request body (use `express-validator` or `zod`)
- Always return consistent JSON: `{ success: true, data: {} }` or `{ success: false, error: "" }`
- Use async/await — no raw `.then()` chains
- Never expose stack traces in production responses

---

## Environment Variables (Backend)

```env
DATABASE_URL=postgresql://user:password@localhost:5432/scoring_app
PORT=3000
NODE_ENV=development
DEVICE_SECRET=some_random_secret
```

---

## Flutter Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.x
  hive_flutter: ^1.x
  dio: ^5.x
  go_router: ^13.x
  uuid: ^4.x
  connectivity_plus: ^6.x
  intl: ^0.19.x

dev_dependencies:
  hive_generator: ^2.x
  build_runner: ^2.x
  flutter_lints: ^3.x
```

---

## Backend Dependencies (package.json)

```json
{
  "dependencies": {
    "express": "^4.x",
    "prisma": "^5.x",
    "@prisma/client": "^5.x",
    "dotenv": "^16.x",
    "cors": "^2.x",
    "uuid": "^9.x",
    "zod": "^3.x"
  },
  "devDependencies": {
    "nodemon": "^3.x"
  }
}
```

---

## Build & Run Commands

### Flutter App

```bash
cd app
flutter pub get
flutter run                  # Run on connected device/emulator
flutter build apk --release  # Build release APK for Play Store
```

### Backend

```bash
cd backend
npm install
npx prisma migrate dev       # Run DB migrations
npx prisma generate          # Generate Prisma client
npm run dev                  # Start dev server with nodemon
```

---

## Important Rules for Claude Code

- **Never** hardcode API URLs — use environment-based config
- **Never** commit `.env` files
- **Always** handle loading, error, and empty states in UI
- **Always** write offline-first: save locally first, sync second
- **Always** use the repository pattern — UI → Provider → Repository → Local/Remote
- When adding a new feature, follow the existing folder structure
- Keep widgets small and composable — no 300-line widget files
- Backend routes must always be validated before hitting the database

---

## Current Status

- [ ] Flutter app scaffold
- [ ] Backend scaffold
- [ ] PostgreSQL schema (Prisma)
- [ ] Live scoring feature
- [ ] Player stats
- [ ] Match history
- [ ] Tournament mode
- [ ] Offline sync
- [ ] Play Store build

---

_Last updated: June 2026_
