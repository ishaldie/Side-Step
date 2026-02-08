# CLAUDE.md — Sidestep Game Project

## Project Overview

**Sidestep** is a mobile dodging/parkour game built with **Godot 4.5** and **GDScript**. Five themed worlds, 25 levels, 72 obstacle types, and a shoe progression system. Player character is "Kai." Target platforms: iOS (primary), Android (secondary). Portrait orientation (480x800).

**Current version:** 2.7.7
**Status:** Near production — visual polish and audio still needed before App Store submission.

## Working Directory

The active game project lives at:
```
Sidestep/sidestep_v2.7.7/sidestep_v2.7.7/
```
Always verify the latest version folder before making changes — a newer version directory may exist.

**Godot editor:** `Sidestep/_tools/Godot_v4.5.1-stable_win64.exe`

## Tech Stack

- **Engine:** Godot 4.5.1 (GL Compatibility rendering)
- **Language:** GDScript
- **Testing:** GUT (Godot Unit Testing) — 4 test files (3 unit + 1 integration), ~86 tests
- **Audio:** Procedurally generated SFX, 1 OGG music track (`High_Score_Heart.ogg`), 3 buses (Master, Music, SFX)
- **Assets:** ~24 custom pixel art sprites + Kenney CC0 packs (fallback for ~48 remaining obstacle types)
- **CI/CD:** GitHub Actions (`.github/workflows/ci.yml` inside project dir)

## Architecture

### Autoload Singletons (9)
Located in `autoload/`:
- `game_manager.gd` — Game state, worlds, levels, save/load (AES-256-CBC encrypted)
- `object_pool.gd` — Object pooling for obstacles/coins (~50 pre-instantiated)
- `audio_manager.gd` — Sound effects and music playback
- `screen_effects.gd` — Screen shake, visual feedback
- `event_bus.gd` — Signal-based decoupled communication
- `ad_manager.gd` — Ad integration framework (stub)
- `analytics.gd` — Analytics and crash reporting (stub)
- `tutorial_manager.gd` — Tutorial system
- `ui_utils.gd` — UI utilities

### Scene Scripts (16)
Located in `scripts/`:
- `player.gd` (742 LOC) — Player movement, state machine, input handling
- `game.gd` (525 LOC) — Main gameplay controller, spawning, scoring
- `obstacle.gd` (617 LOC) — 72 obstacle type definitions, behaviors, collision
- `background_generator.gd` (598 LOC) — Procedural background generation per world
- `game_calculations.gd` — Pure scoring/progress functions (testable)
- `main_menu.gd`, `world_select.gd`, `level_select.gd`, `shop.gd`
- `settings.gd`, `game_over.gd`, `level_complete.gd`, `victory.gd`
- `coin.gd`, `result.gd`, `tutorial_overlay.gd`

### Key Patterns
- **State Machine:** Player controller with 7 states (IDLE, RUNNING, JUMPING, FALLING, DUCKING, DASHING, DEAD)
- **Object Pooling:** Pre-instantiated obstacles and coins for mobile performance
- **Event Bus:** Signals for decoupled communication between systems
- **Singleton Pattern:** Autoloads for global state management
- **Two-Tier Sprites:** ~24 custom pixel art + Kenney fallbacks with color tinting for remaining obstacles

### Project Structure
```
sidestep/
├── autoload/        # 9 singleton scripts (1,628 LOC)
├── scripts/         # 16 scene-attached scripts (4,922 LOC)
├── scenes/          # 13 .tscn scene files
├── test/            # unit/ (3 files) and integration/ (1 file) — 782 LOC
├── assets/
│   ├── kai_sprites/     # Character sprites (4 shoe tiers × 4 poses)
│   ├── sprites/         # obstacles/, shoes/, worlds/, ui/, powerups/
│   ├── backgrounds/     # 6 world background PNGs
│   ├── audio/           # 1 OGG music track
│   └── ui/              # logos, buttons, hud/, world_tiles/
│   └── flags/           # 5 level-complete flag sprites
├── addons/          # GUT testing framework
├── docs/            # 9 documentation files
├── conductor/       # Project context files
├── tools/           # test_sprites.gd utility
├── .github/workflows/ci.yml
└── project.godot    # Godot project configuration
```

### Asset Inventory
- **Character sprites:** 16 total (4 shoe tiers × stand/jump/walk/duck)
- **World backgrounds:** 6 PNGs (city, soccer_field, beach, underwater, volcano, grasslands)
- **Custom obstacle sprites:** ~24 across 5 worlds (cone, barrier, soccer_ball, sand_castle, shark_fin, meteor, etc.)
- **Flags:** 5 world-themed level-complete flags (highest quality assets in project)
- **Shoes (shop):** 4 sprites (barefoot, flip_flops, running_shoes, winged_shoes)
- **UI:** Logo, menu background, 3-state buttons, HUD panels (score, coins, progress, pause)
- **Coins:** 4-frame spin animation spritesheet
- **Powerups:** 3 sprites (magnet, shield, speed_bolt) — not yet integrated into gameplay
- **World tiles:** 5 gold-framed thumbnails for world select screen

## Code Standards

- **Variables/functions:** `snake_case`
- **Classes:** `PascalCase`
- **Signals:** Use `EventBus` for decoupled communication
- **Functions:** Single responsibility, keep focused
- **Object creation:** Use `ObjectPool` for frequently instantiated objects
- **Security:** AES-256-CBC encrypted saves, checksum validation, range validation on loaded data

## Testing

### Test Files
- `test/unit/test_game_calculations.gd` — Scoring, progress, difficulty scaling (30 tests)
- `test/unit/test_game_configs.gd` — World/level validation, balance checks (28 tests)
- `test/unit/test_obstacle_configs.gd` — All 72 obstacles validated (14 tests)
- `test/integration/test_game_manager.gd` — GameManager state transitions (14 tests)

### Testing Guidelines
- Framework: GUT (extends `GutTest`)
- Use `add_child_autofree()` for scene instances, `await get_tree().process_frame` after
- Always call `ObjectPool.clear_pools()` in `after_each()` to prevent orphans
- Star thresholds: 70% = 1 star, 85% = 2 stars, 95% = 3 stars
- `GameManager.calculate_score()` does NOT exist — use `GameCalculations` instead
- Run via GUT test runner scene (`test/run_tests.tscn`) in Godot

## Development Workflow

### TDD Approach
1. Write failing test first
2. Implement minimum code to pass
3. Refactor if needed

### Commit Convention
```
conductor(phase): [Description]
conductor(task): [Description]
conductor(checkpoint): Phase [N] complete
conductor(revert): Revert [scope] - [reason]
```

### Versioning (Semantic)
- **Major:** Breaking changes or overhauls
- **Minor:** New features, worlds, mechanics
- **Patch:** Bug fixes, polish, balance tweaks

**Version bump process:** Bump version in `project.godot` → copy working directory to `sidestep_v<new>/sidestep_v<new>/` → create zip archive in `_archive_versions/`

**Archive history:** v1.0 through v1.7.7 in `_misc/archive/`, v2.7.0 through v2.7.6 in `_archive_versions/`

## Project Context (Conductor)

The `conductor/` directory contains persistent project context:
- `product.md` — Product definition, target users, features
- `product-guidelines.md` — Brand voice, content standards, UX guidelines
- `tech-stack.md` — Technical decisions and architecture
- `workflow.md` — Development methodology and conventions
- `tracks.md` — Master feature track list
- `tracks/` — Individual track files
- `code_styleguides/` — Style reference docs

**Always read these files when starting new work** to maintain consistency.

## Game Design Quick Reference

| World | Theme | Background | Difficulty | Levels |
|-------|-------|-----------|-----------|--------|
| 1 | Road (city traffic) | city.png | 1.0–2.5 | 1–5 |
| 2 | Soccer Field | soccer_field.png | 2.0–3.5 | 6–10 |
| 3 | Beach | beach.png | 3.0–4.5 | 11–15 |
| 4 | Underwater | underwater.png | 4.0–5.5 | 16–20 |
| 5 | Volcano | volcano.png | 5.0–6.5 | 21–25 |

**Shoe Tiers:** Barefoot (free) → Flip Flops (500) → Running Shoes (1500, dash) → Winged Shoes (4000, double jump + dash)

**Star Rating:** 70% = 1 star, 85% = 2 stars, 95% = 3 stars (max 75 stars across all 25 levels)

**Controls:** Input buffering (200ms), coyote time (150ms), touch gestures for mobile

## Known Issues

- **Beach background bug:** World 3 (Beach) currently uses `grasslands.png` instead of `beach.png` in `background_generator.gd`
- **Limited animation:** Character has only 1 walk frame per shoe tier — needs 3-4 frame run cycles
- **Obstacle sprite gap:** ~24/72 obstacles have custom pixel art; remaining ~48 use Kenney fallbacks with color tinting
- **Music:** Only 1 track (`High_Score_Heart.ogg`); needs per-world music
- **Powerups:** Sprites exist (magnet, shield, speed_bolt) but not yet integrated into gameplay
- **Ad/Analytics:** Framework stubs only — not connected to real services

## Production Readiness Checklist

- [x] Core gameplay loop (jump, duck, collect, dodge)
- [x] 5 worlds with 25 levels
- [x] Shop with 4 shoe tiers
- [x] Save/load with encryption
- [x] Settings (SFX/music toggles)
- [x] Pause menu
- [x] Tutorial system
- [x] Object pooling for performance
- [x] 86 unit/integration tests
- [x] CI/CD pipeline
- [x] Privacy policy and age rating docs
- [x] COPPA-compliant (rated 4+/Everyone)
- [ ] Fix beach background bug
- [ ] Add character run animation frames (3-4 per shoe tier)
- [ ] Custom sprites for remaining ~48 obstacle types
- [ ] Per-world music tracks
- [ ] Particle effects (coin collect, hit, death)
- [ ] Integrate powerup system
- [ ] Parallax scrolling for backgrounds
- [ ] App Store screenshots and marketing assets
- [ ] Connect ad/analytics to real services
- [ ] Beta testing pass

## Documentation

Located in `docs/`:
- `APP_STORE_METADATA.md` — Store listing text
- `APPLE_REVIEW_RECOMMENDATIONS.md` — App review prep
- `CHARACTER_REBRAND_ANALYSIS.md` — Kai character analysis
- `COPYRIGHT_REVIEW.md` — Asset licensing review
- `KENNEY_ASSETS_REVIEW.md` — Kenney CC0 usage audit
- `PRIVACY_POLICY.md` — Privacy policy (COPPA compliant)
- `RECOMMENDATIONS.md` — General improvements
- `SENIOR_CODE_REVIEW.md` — Architecture review
- `VISUAL_ASSETS_GUIDE.md` — Sprite/asset reference

Also at project root: `README.md`, `CHANGELOG.md`, `CHANGELOG.txt`, `GRADE_REPORT.md`

## Version Control

### Git Setup
- **Git repo root:** `C:/Users/zrina` (home directory — NOT project-specific)
- **Current branch:** `master` (no commits yet)
- **Main branch:** `main`
- **Remote origin:** None configured — all work is local only
- **CI/CD:** `.github/workflows/ci.yml` exists inside project dir but no remote to push to

### Manual Versioning System
Since there is no active git workflow, the project uses a **manual directory-based versioning** system:
1. Each version lives in its own folder: `Sidestep/sidestep_v<version>/sidestep_v<version>/`
2. Previous versions are archived as zip files in `_archive_versions/` (v2.7.0–v2.7.6)
3. Legacy versions (v1.0–v1.7.7) archived in `_misc/archive/`
4. Version number tracked in `project.godot` under `config/version`

### Version Bump Process
1. Update `config/version` in `project.godot`
2. Copy entire working directory to `sidestep_v<new>/sidestep_v<new>/`
3. Create zip archive of previous version in `_archive_versions/`
4. Update `CHANGELOG.md` with changes

### Version History
| Version | Location | Notes |
|---------|----------|-------|
| 1.0–1.7.7 | `_misc/archive/*.zip` | Legacy pre-overhaul releases |
| 2.7.0–2.7.6 | `_archive_versions/*.zip` | Archived previous releases |
| **2.7.7** | `sidestep_v2.7.7/` | **Current active version** |

### Recommended: Setting Up Proper Git
To improve version control, consider:
1. Initialize a git repo inside the project directory (not home dir)
2. Add a `.gitignore` for Godot (`.godot/`, `*.import`, `export_presets.cfg`)
3. Connect to a GitHub/GitLab remote for backup
4. Use branches for features (`feature/powerups`, `fix/beach-background`, etc.)

## Important Notes

- The game is rated 4+/Everyone and must remain COPPA compliant
- Kenney assets are CC0 licensed (free to use)
- The `old/` directory (if present) contains legacy pre-versioning releases — do not modify
- Total project code: ~6,550 LOC (autoload + scripts) + 782 LOC (tests) = ~7,332 LOC
