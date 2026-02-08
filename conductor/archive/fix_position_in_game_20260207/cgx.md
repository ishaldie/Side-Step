# CGX — Conductor Growth Experience

## Track: Positioning Review & Obstacle Classification

*Lessons learned and workflow improvements will be recorded here as the track progresses.*

- [2026-02-07] Located positioning sources in `scripts/game.gd`, `scripts/player.gd`, `scripts/obstacle.gd`, and `scenes/game.tscn` (ground + player placement). 
- [2026-02-08] Red-phase tests for obstacle classification (`avoidance`) and lane mapping (`spawn_lane`) immediately exposed missing config metadata across all obstacle types, which confirms the next implementation target is central config enrichment.
- [2026-02-08] Running GUT from the wrong subfolder caused false "file not found" for `gut_cmdln.gd`; anchoring test runs to `Sidestep/project.godot` removed ambiguity.
- [2026-02-08] `game.gd` and tests access `obstacle.gd.CONFIGS` on the script type, so metadata generation must be exposed as `static var CONFIGS`; plain instance `var` breaks parse-time member resolution.
- [2026-02-08] Centralized constants in `game.gd`/`player.gd` require `preload("res://scripts/positioning_config.gd")`; direct class-name constant references failed parse-time constant-expression checks in this project setup.
- [2026-02-07] Fixed `or true` bug in `test_ground_or_flying_specified` — was always passing.
- [2026-02-07] Added 10 new failing tests: avoidance classification (1), spawn_lane (1), floor/player alignment (5), spawn lane consistency (4). Key insight: obstacle CONFIGS currently lack `avoidance` and `spawn_lane` fields entirely — Phase 2 will add these.
- [2026-02-07] Ground collision alignment: Ground StaticBody at y=680, collision top at y=680. Player GROUND_Y=650 means player center 30px above ground collision. Player sprite offset -37 puts feet at ~650. Game GROUND_LEVEL_Y=650 matches. This alignment is intentional and correct.
- [2026-02-08] Lane placement based on config height was unreliable once collision switched to rendered sprite size. Aligning obstacle `position.y` from actual collision bounds (inside `obstacle.gd`) removed per-texture drift and made jump/duck profiles consistent across all obstacle assets.
- [2026-02-08] Duck-lane scene alignment drifted because `barrier` had a hardcoded offset (-85) while centralized duck lane is `GROUND_Y -> DUCK_OBSTACLE_Y` (-80). Computing duck-lane `height_offset` from `PositioningConfig` keeps sprite/collision placement consistent.
