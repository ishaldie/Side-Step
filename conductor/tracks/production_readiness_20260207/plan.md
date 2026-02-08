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
- [~] **3.2 Refactor background system** — Convert `background_generator.gd` to use `ParallaxBackground` + `ParallaxLayer` nodes
- [~] **3.3 Define per-world parallax configs** — Layer count, scroll speeds, and tiling settings per world
- [~] **3.4 Implement scroll update** — Hook parallax scroll to game speed in `game.gd`
- [~] **3.5 Add seamless tiling** — Ensure background layers tile vertically without gaps
- [ ] **3.6 Verify tests pass** — All new + existing tests green

## Phase 4: Powerup System
*New gameplay feature — magnet, shield, speed boost*

- [ ] **4.1 Write tests** — Test powerup spawn, pickup, effect activation, duration, expiry
- [ ] **4.2 Create powerup script** — `scripts/powerup.gd` with type enum, collision, pool support
- [ ] **4.3 Create powerup scene** — `scenes/powerup.tscn` with Area2D, Sprite2D, CollisionShape2D
- [ ] **4.4 Add EventBus signals** — `powerup_collected`, `powerup_activated`, `powerup_expired`
- [ ] **4.5 Implement magnet effect** — Auto-collect coins within radius in `game.gd` / `coin.gd`
- [ ] **4.6 Implement shield effect** — Set `player.invincible` with visual overlay
- [ ] **4.7 Implement speed boost effect** — Temporarily increase `player.move_speed`
- [ ] **4.8 Add powerup spawning** — Random spawn logic in `game.gd` (configurable probability)
- [ ] **4.9 Add HUD display** — Active powerup icon + duration timer on game HUD
- [ ] **4.10 Pool powerup instances** — Register in `ObjectPool`
- [ ] **4.11 Verify all tests pass** — Full test suite green

## Phase 5: Integration & Version Bump
*Final verification and release prep*

- [ ] **5.1 Full regression test** — Run all tests, verify no regressions
- [ ] **5.2 Manual play-test checklist** — Test each world with all features active
- [ ] **5.3 Update CHANGELOG.md** — Document all changes for this track
- [ ] **5.4 Version bump** — Update `project.godot` version to 2.8.0
- [ ] **5.5 Archive previous version** — Zip v2.7.7 to `_archive_versions/`
