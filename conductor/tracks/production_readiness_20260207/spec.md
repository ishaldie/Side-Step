# Spec: Production Readiness — Bug Fixes & Polish

## Overview
Bring Sidestep v2.7.7 closer to App Store submission by fixing the known beach background bug, adding particle effects for visual polish, implementing parallax scrolling backgrounds, and integrating the existing powerup sprites into playable gameplay.

## Requirements

### R1: Fix Beach Background Bug
- World 3 (Beach, index 2) currently loads `grasslands.png` instead of `beach.png`
- Fix the mapping in `background_generator.gd` line 16
- Verify `beach.png` exists at `res://assets/backgrounds/beach.png`

### R2: Particle Effects
- **Coin Collection:** Burst of gold/yellow particles at coin position when collected
- **Player Hit:** Red/orange impact particles on obstacle collision
- **Player Death:** Larger burst/explosion particles on death
- Use `CPUParticles2D` (better mobile compatibility than GPU particles)
- Particles should auto-free after emission completes (one-shot)
- Pool particle instances via `ObjectPool` for performance

### R3: Parallax Scrolling Backgrounds
- Convert static background sprites to multi-layer parallax system
- Minimum 2 layers: far background (slow scroll) + near elements (faster scroll)
- Scroll speed proportional to obstacle/game scroll speed
- Each world should have its own parallax configuration
- Must tile seamlessly for infinite vertical scrolling
- Maintain current fallback to procedural background if no image available

### R4: Powerup System Integration
- Create `powerup.gd` script (similar structure to `coin.gd`)
- Three powerup types using existing sprites:
  - **Magnet** (`magnet.png`): Auto-collects coins within radius for duration
  - **Shield** (`shield.png`): Grants temporary invincibility (uses existing `player.invincible`)
  - **Speed Boost** (`speed_bolt.png`): Increases player move speed temporarily
- Spawn powerups randomly during gameplay (configurable probability per level)
- Pool powerups via `ObjectPool`
- Visual indicator on player when powerup is active
- HUD display for active powerup + remaining duration
- Emit signals via `EventBus` for powerup events

## Acceptance Criteria
- [ ] World 3 (Beach) displays `beach.png` background
- [ ] Gold particle burst plays on every coin collection
- [ ] Red particle burst plays on player hit
- [ ] Death particle effect plays on player death
- [ ] Backgrounds scroll with parallax effect during gameplay
- [ ] All 3 powerup types spawn, activate, and expire correctly
- [ ] Powerup effects are visible on HUD
- [ ] All existing 86 tests still pass
- [ ] New tests written for powerup logic and particle triggers
- [ ] No performance regression on mobile (60fps target maintained)

## Out of Scope
- Per-world music tracks (separate track)
- Character run animation frames (separate track)
- Custom sprites for remaining ~48 obstacles (separate track)
- Ad/analytics integration (separate track)
- App Store screenshots and marketing (separate track)
