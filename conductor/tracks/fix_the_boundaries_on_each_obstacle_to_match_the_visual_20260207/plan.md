# Implementation Plan: Fix Obstacle Boundaries to Match Visuals

## Phase 1: Tests & Discovery

- [x] **1.1 Audit current collision vs visual sizing** — Collision uses config W*H * 0.8, visual uses tex * uniform_scale(max(W,H)*1.2/max(tex)). Collision is 30-70% smaller than visual across all obstacles.
- [x] **1.2 Write failing tests** — Created test/unit/test_obstacle_boundaries.gd with 6 tests: width/height matching, bounds check, ratio consistency, aspect ratio, duck-under offset alignment. All fail because collision uses config dims not rendered dims.

## Phase 2: Fix Collision Sizing

- [ ] **2.1 Refactor _setup_collision to use rendered sprite size** — After sprite texture and scale are set, derive collision from actual rendered dimensions instead of config width/height
- [ ] **2.2 Handle edge cases** — Obstacles with height_offset, flip_v, non-square textures, missing textures (fallback)
- [ ] **2.3 Verify tests pass** — All new + existing tests green

## Phase 3: Verification

- [ ] **3.1 Manual review** — Spot-check at least 1 obstacle per world in-game
- [ ] **3.2 Update changelog** — Document the collision fix

---
