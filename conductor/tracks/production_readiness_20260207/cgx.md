# CGX — Conductor Growth Experience

## Track: Production Readiness — Bug Fixes & Polish

*Lessons learned and workflow improvements will be recorded here as the track progresses.*

- [2026-02-07] Phase 1: Beach background was a 1-line fix (grasslands.png → beach.png). Test added to catch regressions.
- [2026-02-07] Phase 2: CPUParticles2D with one_shot + auto-free timer is the simplest approach for mobile particles. Pooling adds complexity with no measurable benefit for sub-0.5s lifetimes.
- [2026-02-07] Phase 3: ParallaxBackground requires motion_mirroring set to the sprite width for seamless tiling. Duplicate sprites in each layer ensure no gaps during fast scrolling.
- [2026-02-07] Phase 4: Powerup `body_entered` signal only fires for CharacterBody2D — Area2D collision_mask must include the player's layer (1). Using `level_data.get("powerup_chance", 0.05)` avoids modifying all 25 level definitions.
- [2026-02-08] Phase 5: Version bump requires updating both `project.godot` and `game_manager.gd` GAME_VERSION constant — CI checks consistency between them.
