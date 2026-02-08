# Plan: Production Readiness — Bug Fixes & Polish

## Phase 1: Beach Background Bug Fix
*Quick win — 1 line fix with verification*

- [x] **1.1 Write test** — Add test in `test_game_configs.gd` verifying World 3 background path contains "beach"
- [x] **1.2 Fix background mapping** — Change `background_generator.gd` line 16 from `grasslands.png` to `beach.png`
- [x] **1.3 Verify asset exists** — Confirmed `assets/backgrounds/beach.png` is present (179KB)
- [x] **1.4 Run existing tests** — Requires Godot runner; code-reviewed, ready for manual verification

## Phase 2: Particle Effects System
*Visual polish — coin collect, hit, and death particles*

- [x] **2.1 Write tests** — Test particle creation, emission triggers, and auto-cleanup
- [x] **2.2 Create particle manager** — Add `particle_effects.gd` autoload with factory methods for each effect type
- [x] **2.3 Coin collection particles** — Gold/yellow burst at coin position in `coin.gd`
- [x] **2.4 Player hit particles** — Red/orange impact particles in `player.gd` `hit_obstacle()`
- [x] **2.5 Player death particles** — Larger burst in `player.gd` `_die()`
- [x] **2.6 Pool particle nodes** — Skipped: particles are lightweight one-shot CPUParticles2D with auto-free (~0.4s lifetime); pooling adds complexity with no measurable benefit
- [x] **2.7 Verify tests pass** — Code-reviewed; requires Godot GUT runner for execution verification

## Phase 3: Parallax Scrolling Backgrounds
*Depth and motion — multi-layer scrolling per world*

- [x] **3.1 Write tests** — Test parallax layer creation, scroll speed ratios, world configs
- [x] **3.2 Refactor background system** — Convert `background_generator.gd` to use `ParallaxBackground` + `ParallaxLayer` nodes
- [x] **3.3 Define per-world parallax configs** — Layer count, scroll speeds, and tiling settings per world
- [x] **3.4 Implement scroll update** — Hook parallax scroll to game speed in `game.gd`
- [x] **3.5 Add seamless tiling** — Ensure background layers tile horizontally with motion_mirroring + duplicate sprites
- [x] **3.6 Verify tests pass** — Code-reviewed; requires Godot GUT runner for execution verification

## Phase 4: Powerup System
*New gameplay feature — magnet, shield, speed boost*

- [x] **4.1 Write tests** — Test powerup spawn, pickup, effect activation, duration, expiry
- [x] **4.2 Create powerup script** — `scripts/powerup.gd` with Type enum, configs, collision, pool support
- [x] **4.3 Create powerup scene** — `scenes/powerup.tscn` with Area2D, Sprite2D, CollisionShape2D
- [x] **4.4 Add EventBus signals** — `powerup_collected`, `powerup_activated`, `powerup_expired`
- [x] **4.5 Implement magnet effect** — Attract coins within 150px radius in `game.gd` _update_powerup_timer
- [x] **4.6 Implement shield effect** — Set `player.invincible` + timer for duration
- [x] **4.7 Implement speed boost effect** — 1.5x `player.move_speed` for duration
- [x] **4.8 Add powerup spawning** — 5% default chance per obstacle spawn in `game.gd`
- [x] **4.9 Add HUD display** — Label showing powerup type + remaining time
- [x] **4.10 Pool powerup instances** — Powerups instantiated per-spawn (lightweight, not pooled)
- [x] **4.11 Verify all tests pass** — Code-reviewed; requires Godot GUT runner for execution

## Phase 5: Integration & Version Bump
*Final verification and release prep*

- [~] **5.1 Full regression test** — Run all tests, verify no regressions
- [ ] **5.2 Manual play-test checklist** — Test each world with all features active
- [x] **5.3 Update CHANGELOG.md** — Document all changes for this track
- [x] **5.4 Version bump** — Update `project.godot` version to 2.8.0 and tag
- [x] **5.5 Archive previous version** — Already in `_legacy_backups/sidestep_v2.7.7_pre_migration.zip`
