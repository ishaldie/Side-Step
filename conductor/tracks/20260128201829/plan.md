# Plan: Animal Runner Character (Rabbit)

**Track ID**: 20260128201829
**Status**: Not Started
**Spec**: [spec.md](spec.md)

## Phase 1: Asset Sourcing & Preparation

- [ ] Task 1.1: Search Kenney.nl for rabbit/bunny character sprites
- [ ] Task 1.2: Search itch.io for Kenney-style rabbit sprites (free or paid)
- [ ] Task 1.3: If no suitable assets found, create sprite requirements doc for commissioning/AI generation
- [ ] Task 1.4: Download and verify sprite dimensions match needed format (~70x94px like current aliens)
- [ ] Task 1.5: Create 4 color variants if source only has 1 color (recolor in image editor)

**Deliverable**: `assets/kenney/players/rabbit*.png` files (28 sprites: 7 poses × 4 colors)

## Phase 2: Asset Integration

- [ ] Task 2.1: Add rabbit sprites to `assets/kenney/players/` folder with naming convention:
  - `rabbitBrown_*.png` (Barefoot)
  - `rabbitWhite_*.png` (Flip Flops)
  - `rabbitBlue_*.png` (Running Shoes)
  - `rabbitGold_*.png` (Winged Shoes)
- [ ] Task 2.2: Update `player.gd` `SHOE_TO_ALIEN` constant to `SHOE_TO_CHARACTER`:
  ```gdscript
  const SHOE_TO_CHARACTER: Dictionary = {
      0: "Brown",   # BAREFOOT
      1: "White",   # FLIP_FLOPS
      2: "Blue",    # RUNNING_SHOES
      3: "Gold"     # WINGED_SHOES
  }
  ```
- [ ] Task 2.3: Update `_load_textures()` to use `rabbit` prefix instead of `alien`
- [ ] Task 2.4: Adjust `PLAYER_SPRITE_SCALE` if rabbit proportions differ from aliens
- [ ] Task 2.5: Test sprite loading - verify no missing texture errors in console

## Phase 3: Visual Tuning & Polish

- [ ] Task 3.1: Test all 4 shoe tiers in-game, verify correct sprites load
- [ ] Task 3.2: Adjust sprite Y offset if feet don't align with ground properly
- [ ] Task 3.3: Verify wing overlay position works with rabbit body shape
- [ ] Task 3.4: Test all animation states (idle, run, jump, duck, dash, death)
- [ ] Task 3.5: Verify character reads well at mobile scale (run on device or emulator)

## Phase 4: Testing & Verification

- [ ] Task 4.1: Play through World 1 Level 1 with each shoe tier
- [ ] Task 4.2: Verify collision detection still works correctly (hitbox unchanged)
- [ ] Task 4.3: Run existing GUT tests to ensure no regressions
- [ ] Task 4.4: Test on mobile device/emulator for visual clarity
- [ ] Task 4.5: Update shop UI descriptions if needed (currently references "shoe" which still applies)

## Checkpoints

- [ ] Phase 1 Complete [checkpoint: ]
- [ ] Phase 2 Complete [checkpoint: ]
- [ ] Phase 3 Complete [checkpoint: ]
- [ ] Phase 4 Complete [checkpoint: ]

## Notes

### Current Code Reference (`player.gd:156-208`)
```gdscript
const SHOE_TO_ALIEN: Dictionary = {
    0: "Beige",   # BAREFOOT
    1: "Pink",    # FLIP_FLOPS
    2: "Blue",    # RUNNING_SHOES
    3: "Yellow"   # WINGED_SHOES
}

func _load_textures() -> void:
    var shoe_type: int = GameManager.current_shoe
    var alien_color: String = SHOE_TO_ALIEN.get(shoe_type, "Blue")
    var base_path: String = "res://assets/kenney/players/alien%s_" % alien_color
    # ... loads stand, walk1, walk2, jump, duck, hit, front
```

### Required Sprite Files (per color)
1. `stand.png` - Idle pose
2. `walk1.png` - Walk frame 1
3. `walk2.png` - Walk frame 2
4. `jump.png` - Jumping pose
5. `duck.png` - Ducking pose
6. `hit.png` - Hurt/death pose
7. `front.png` - Front-facing (for menus)

### Sprite Dimensions
- Current alien sprites: ~70x94 pixels
- Scale applied: 0.45 → renders at ~32x42 pixels
- Must maintain similar proportions for collision compatibility
