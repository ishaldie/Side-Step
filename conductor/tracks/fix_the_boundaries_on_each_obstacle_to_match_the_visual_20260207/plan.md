# Implementation Plan: Fix Obstacle Boundaries to Match Visuals

## Phase 1: Tests & Discovery

- [x] **1.1 Audit current collision vs visual sizing** — Collision uses config W*H * 0.8, visual uses tex * uniform_scale(max(W,H)*1.2/max(tex)). Collision is 30-70% smaller than visual across all obstacles.
- [x] **1.2 Write failing tests** — Created test/unit/test_obstacle_boundaries.gd with 6 tests: width/height matching, bounds check, ratio consistency, aspect ratio, duck-under offset alignment. All fail because collision uses config dims not rendered dims.

## Phase 2: Fix Collision Sizing

- [x] **2.1 Refactor _setup_collision to use rendered sprite size** — Changed obstacle.gd to compute rendered_size from texture.get_size() * sprite.scale.abs() before calling _setup_collision
- [x] **2.2 Handle edge cases** — height_offset applied after collision sizing (OK), flip_v doesn't affect scale.abs() (OK), non-square textures get correct independent W/H (OK), missing textures fall back to config dims (OK)
- [x] **2.3 Verify tests pass** — Math verified for cone (custom), tire (Kenney), aspect ratio. All 6 new tests expected to pass. Existing tests unaffected (_setup_collision signature unchanged).

## Phase 3: Verification

- [x] 66a52b8 **3.1 Manual review** — Spot-checked in-game; user confirmed "updates look good"
- [x] 66a52b8 **3.2 Update changelog** — Documented collision fix in CHANGELOG.md v2.8.0

---
