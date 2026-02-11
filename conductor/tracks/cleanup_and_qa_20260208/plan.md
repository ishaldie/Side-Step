# Implementation Plan: Cleanup and QA

## Phase 1: Critical Fixes

- [x] Task: Change TEST_MODE to OS.is_debug_build() in game_manager.gd and ad_manager.gd `9f573f4`
- [x] Task: Obfuscate encryption key via runtime _derive_save_key() `9f573f4`
- [x] Task: Delete unused Result class (result.gd, 119 LOC) `9f573f4`

## Phase 2: Bug Fixes (High Priority)

- [x] Task: Add null check for current_scene in particle_effects.gd `9f573f4`
- [x] Task: Replace duplicate _add_coin_icon with UIUtils in level_complete.gd and victory.gd `9f573f4`
- [x] Task: Fix star display to use filled/empty textures in level_complete.gd `9f573f4`
- [x] Task: Remove dead _is_flying_obstacle() from game.gd `9f573f4`
- [x] Task: Fix coin spawn order (reset before setup) in game.gd `9f573f4`
- [x] Task: Add flying_ball and lava_bubble to PRELOADED_CUSTOM in obstacle.gd `9f573f4`
- [x] Task: Fix player sprite scale drift in squash/stretch (player.gd) `9f573f4`
- [x] Task: Use DEATH_COIN_PENALTY constant in game_over.gd `9f573f4`

## Phase 3: Code Quality (High Priority)

- [x] Task: Consolidate CUSTOM_SPRITE_MAP into PRELOADED_CUSTOM in obstacle.gd `9f573f4`
- [x] Task: Preload shoe icons in shop.gd `9f573f4`
- [x] Task: Verify input debouncing (already handled by _scene_transition_locked) `9f573f4`

## Phase 4: Code Quality (Medium Priority)

- [x] Task: Remove redundant _load_textures() call in player.gd _ready() `9f573f4`
- [x] Task: Preload textures in world_select.gd and level_select.gd `9f573f4`
- [x] Task: Rename analytics score parameter to distance, fix int cast `9f573f4`
- [x] Task: Give TutorialManager its own save path `9f573f4`

## Phase 5: Test Fixes

- [x] Task: Fix test_particles_added_to_scene_tree for null current_scene `20cb511`

---

[checkpoint: 20cb511]
