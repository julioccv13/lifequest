# LifeQuest

Offline-first life coaching RPG. Chat with LifeQuest AI, store your game state locally, and track quests, stats, and check-ins without any paid backend.

## Features
- Chat tab with conversation list and AI coach (optional LLM)
- Dashboard for daily game state (phase, stats, quests, rules, feedback loops)
- Quest Log with steps, difficulty, XP, and status
- Insights with weekly/monthly summaries and charts
- Local-only SQLite storage + JSON export/import

## Project setup
1. Install Flutter (latest stable) and ensure `flutter doctor` is clean.
2. From this directory, run:

```bash
flutter pub get
```

If this folder does not include the generated `android/` or `ios/` directories, run:

```bash
flutter create .
```

Then re-run `flutter pub get`.

## Run
```bash
flutter run
```

## Web (local + GitHub Pages)
Local web run:
```bash
flutter run -d chrome
```

Build for GitHub Pages (base href required):
```bash
flutter build web --release --base-href "/lifequest/"
```

GitHub Pages deployment:
1. Push to `main` (workflow in `.github/workflows/deploy_pages.yml` builds and deploys).
2. In repo Settings -> Pages, set Source to "GitHub Actions".
3. Access: `https://<username>.github.io/lifequest/`.

Install on iPhone/iPad:
1. Open the GitHub Pages URL in Safari.
2. Tap Share -> "Add to Home Screen".
3. Launch LifeQuest from the home screen icon.

## LLM endpoint contract
Request JSON:
```json
{
  "mode": "chat" | "extract",
  "coach_prompt": "...",
  "extraction_prompt": "...",
  "schema": {"date": "YYYY-MM-DD", "phase": "Limbo|Vision|Flow|Resistance|null"},
  "messages": [{"role": "user", "content": "...", "created_at": 123}],
  "previous_state": {"phase": "Vision"}
}
```

Response JSON:
```json
{
  "state": {"phase": "Vision", "stats": {"energy": 7}},
  "quests": [{"id": "...", "title": "..."}],
  "checkin": {"mood": 6, "energy": 7, "focus": 5}
}
```

## Data model
Local SQLite tables:
- `conversations` (id, title, created_at)
- `messages` (id, conversation_id, role, content, created_at)
- `game_state_daily` (date, phase, character_json, stats_json, main_quest_json, side_quests_json, rules_json, rewards_json, tutorial_json, feedback_json, quest_log_json, narrative_summary, updated_at)
- `quests` (id, type, title, description, domain, difficulty, xp, status, steps_json, created_at, updated_at)
- `checkins` (id, date, mood, energy, focus, notes)
- `settings` (id=1, coach_prompt, extraction_prompt, schema_json, llm_enabled, llm_endpoint, llm_api_key, timezone)

## Sample data
A demo export file lives at `sample_data.json`. Import it from the Settings screen using the file path to quickly populate the app.

## Notes
- API keys are stored locally with basic base64 obfuscation (not secure).
- All data stays on device unless LLM is enabled.
