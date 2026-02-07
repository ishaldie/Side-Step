# Side Step Changelog

## v2.7.7 (2026-02-05)

### DevOps
- Added GitHub Actions CI/CD pipeline (`.github/workflows/ci.yml`)
- Automated GUT unit and integration test runs on push/PR
- Project structure validation (checks for required directories)
- Version consistency check (project.godot vs game_manager.gd)

---

## v2.7.6 (2026-02-05)

### Bug Fixes
- Added scene transition lock to prevent double/race-condition scene changes
- Transition lock auto-releases on next frame via `call_deferred`
- Duplicate transition attempts are logged with warnings

---

## v2.7.5 (2026-02-05)

### Security
- Save files are now encrypted using AES-256-CBC via Godot's `save_encrypted_pass()`
- Automatic fallback to unencrypted save for backward compatibility with older versions
- Encrypted saves stored at `user://sidestep_save.enc`
- Save version bumped to 3 for encrypted format

---

## v2.7.4 (2026-02-05)

### New Features
- Added local crash reporting system to Analytics autoload
- Crash entries include timestamp, game version, session ID, and context
- Added `log_crash()`, `get_crash_log()`, and `clear_crash_log()` API methods
- Crash events are persisted to `user://crash_log.txt` and logged as analytics events

---

## v2.7.3 (2026-02-05)

### Bug Fixes
- Touch input positions are now clamped to valid screen bounds before processing
- Guard against division by zero if screen height is zero or negative
- Touch-end swipe calculations use clamped positions for consistent behavior
- Touch drag duck-zone detection uses safe normalized Y values

---

## v2.7.2 (2026-02-05)

### Security
- Added checksum validation to save files to detect corruption and tampering
- Save files now include game_version in metadata
- Loaded data is range-validated (shoe index clamped, coin count non-negative, stars 0-3)
- Boolean type enforcement for unlocked_shoes array on load
- Checksum mismatch logs a warning (graceful - does not reject pre-checksum saves)

---

## v2.7.1 (2026-02-05)

### Bug Fixes
- Added safe scene transition helper with ResourceLoader.exists() checks and fallback to main menu
- All scene navigation (start_level, restart, complete_level, game_over, menus) now uses error-checked transitions
- Flag texture loading in game.gd now validates resource existence before load()
- Background generator checks ResourceLoader.exists() before loading background images and ground tiles
- Obstacle texture runtime cache now validates resource existence and logs warnings for missing textures

---

## v2.0.0 (2026-01-28)

### New Features
- **New Character: Kai** - Replaced Kenney alien sprites with custom Kai character
  - 4 shoe tiers: Barefoot, Flip Flops, Running Shoes, Winged
  - 5 poses per tier: Stand, Walk1, Walk2, Jump, Duck
- **New Backgrounds** (added to assets, integration pending)
  - Soccer field stadium
  - City street with shops
  - Underwater ocean scene

### Changes
- Updated player sprite system to use Kai sprites
- Player scale adjusted for new character proportions
- Collision shapes updated to match new character size
- Wings are now part of the Winged tier sprite (no polygon overlay)

### Technical
- Added sprite processing scripts for asset pipeline
- Set up Conductor for project management

---

## v1.9.2 (Previous)
- Kenney alien character sprites
- 5 worlds, 25 levels
- Shoe progression system
