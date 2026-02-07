# Product Definition — Sidestep

## Vision
Sidestep is a mobile dodging/parkour game where players control "Kai" through five themed worlds, dodging obstacles, collecting coins, and unlocking shoe upgrades. Simple to learn, challenging to master.

## Target Users
- **Primary:** Casual mobile gamers (ages 4+, COPPA compliant)
- **Platform:** iOS (primary), Android (secondary)
- **Session length:** 1-3 minutes per level (pick-up-and-play)

## Core Value Proposition
Fast-paced, accessible dodging gameplay with progression through themed worlds and a shoe upgrade system that unlocks new abilities.

## Key Features
1. **5 Themed Worlds** — Road, Soccer Field, Beach, Underwater, Volcano (25 levels total)
2. **72 Obstacle Types** — World-themed obstacles with unique behaviors
3. **Shoe Progression** — 4 tiers: Barefoot -> Flip Flops -> Running Shoes (dash) -> Winged Shoes (double jump + dash)
4. **Star Rating System** — 70%/85%/95% thresholds, max 75 stars
5. **Coin Economy** — Collect coins to purchase shoe upgrades in shop
6. **Save System** — AES-256-CBC encrypted with checksum validation
7. **Object Pooling** — Performance-optimized for mobile devices
8. **Tutorial System** — Guided onboarding for new players

## Current Status: Near Production (v2.7.7)
- Core gameplay loop complete
- All 5 worlds and 25 levels playable
- Shop, settings, save/load functional
- 86 unit/integration tests passing
- CI/CD pipeline configured

## Remaining Work (Pre-Launch)
- Fix beach background bug (World 3 uses wrong texture)
- Add character run animation frames (3-4 per shoe tier)
- Custom sprites for remaining ~48 obstacle types
- Per-world music tracks
- Particle effects (coin collect, hit, death)
- Integrate powerup system (magnet, shield, speed)
- Parallax scrolling for backgrounds
- App Store screenshots and marketing assets
- Connect ad/analytics stubs to real services
- Beta testing pass
