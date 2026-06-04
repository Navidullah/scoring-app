# CricLive — Google Play Store Submission Checklist

Everything you need to publish CricLive. Items marked **[YOU]** require an action
only you can do (console clicks, account); the rest is prepared in this repo.

---

## 0. One-time account setup  **[YOU]**
- [ ] Pay the **$25 Google Play Console** one-time registration fee and finish identity verification: https://play.google.com/console
- [ ] Enable **GitHub Pages** for the privacy policy:
      GitHub repo → **Settings → Pages → Source: `main` / folder `/docs`** → Save.
      It will publish at **https://navidullah.github.io/scoring-app/** (open it once to confirm it loads).

## 1. Build artifacts (prepared)
- [x] **App name:** CricLive (launcher + in-app)
- [x] **Package (applicationId):** `com.cricketscoring.scoring_app` (permanent once published — do NOT change later)
- [x] **Version:** 1.0.0 (versionCode 1) — fine for first release
- [x] **Signed release AAB:** `app/build/app/outputs/bundle/release/app-release.aab`
      (signed with the upload keystore — see `production-deploy-and-release` notes; BACK UP the keystore)
- [x] **App icon:** set (neon cricket ball)

> Build command (already run for you): `flutter build appbundle --release`
> Upload the **.aab** (not the .apk) to Play Console.

## 2. Store listing (prepared — see `store/play_listing.md`)
- [x] Title: **CricLive: Cricket Scorer**
- [x] Short description (80 chars)
- [x] Full description (SEO-tuned)
- [ ] **[YOU]** Paste them into Play Console → **Main store listing**

### Graphics
- [x] **App icon 512×512:** `store/icon_512.png`
- [ ] **Feature graphic 1024×500:** `store/feature_graphic_1024x500.png` — **NEEDS REBRAND to "CricLive"** (current one says the old name). Easiest: recreate in Canva with the neon icon + "CricLive" + tagline "Score • Share Live • Tournaments". *(I can't generate the image file; you or a designer make this.)*
- [x] **Phone screenshots (10):** `store/play_screens/01..10` — pick at least 4 (Play allows up to 8). Recommended order:
      1. `03_live_scoring` (ball-by-ball)
      2. `04_live_matches` (LIVE feed — your differentiator)
      3. `05_live_viewer` (scorecard + Manhattan)
      4. `09_tournament_detail` (points table)
      5. `07_leaderboards`
      6. `01_home`
      7. `02_match_setup` (ball type / LBW)
      8. `10_settings`
- [ ] **[YOU]** Upload screenshots in Play Console → Store listing.

## 3. App content / policy forms  **[YOU]** (Play Console → Policy → App content)

### Privacy policy
- [ ] URL: **https://navidullah.github.io/scoring-app/** (after enabling Pages)

### Data safety — answers to enter
- **Does your app collect or share user data?** → **Yes**
- **Is all data encrypted in transit?** → **Yes** (HTTPS)
- **Do you provide a way to request data deletion?** → **Yes** (users email us with their Device ID, shown in Settings)
- **Data types:**
  | Data type | Collected | Shared | Why | Notes |
  |---|---|---|---|---|
  | **Personal info → Names** (team & player names the user types) | Yes | **Yes** | App functionality | Live matches are public: names appear in the live feed and the shareable web link. |
  | **Device or other IDs** (anonymous app-generated UUID) | Yes | No | App functionality | Used to group the user's own matches for backup/sync; not an advertising ID. |
- Mark data collection as **required** for the live/sync features (the app still scores fully offline).
- **No** location, **No** financial info, **No** contacts, **No** ads/3rd-party analytics.

### Content rating (IARC questionnaire)
- Category: **Utility / Sports**. No violence, sexual, drug, or gambling content.
- It DOES let users **share user-generated content publicly** (live match text). Answer that honestly when asked; expected rating stays **Everyone / PEGI 3**.

### Ads
- **Contains ads? → No**

### Target audience & content
- Target age: **13+** (or "18 and over" if you prefer to avoid the kids-program requirements). Not designed for children.

### Government apps / News / COVID / Data deletion / Financial features
- All **No / Not applicable**.

## 4. Release  **[YOU]**
- [ ] Play Console → **Production → Create new release** → upload `app-release.aab`
- [ ] Release name: `1.0.0 (1)`; Release notes: "First release of CricLive — live cricket scoring, sharing & tournaments."
- [ ] Set **Countries/regions** (e.g. India, Pakistan, Bangladesh + worldwide)
- [ ] Review & **roll out** (first review can take a few days)

## 5. Good-to-know (not blockers)
- Backend is on Render free tier (sleeps after 15 min). The keep-alive GitHub Action helps; consider a paid tier later for instant live loads at scale.
- Target SDK: Flutter's current default meets Google's required target API level for new apps (verify Console doesn't warn at upload; if it does, bump `targetSdk` in `app/android/app/build.gradle.kts`).
- Keep the **upload keystore + password backed up** — losing them means you can never update CricLive.

---

### Quick status
✅ Prepared by me: app build/signing, name, screenshots, listing copy, privacy policy (rebranded + live disclosure), this checklist + data-safety answers.
🔲 Needs you: $25 registration, enable GitHub Pages, rebrand the feature graphic, then paste listing + upload AAB/screenshots + fill the forms in Play Console.
