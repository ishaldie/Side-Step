# Product Guidelines — Sidestep

## Brand Voice
- **Fun and encouraging** — Celebrate player achievements, never punitive
- **Kid-friendly** — All content appropriate for ages 4+ (COPPA compliant)
- **Simple language** — Short, clear UI text; no jargon

## Content Standards
- No violence beyond cartoon-style dodging obstacles
- No in-app purchases that exploit children
- No collection of personal data from minors
- All third-party assets must be properly licensed (CC0 or equivalent)

## UX Guidelines
- **Portrait orientation** (480x800) — designed for one-handed play
- **Touch-first controls** — Swipe gestures for mobile, keyboard fallback for testing
- **Input buffering** (200ms) — Forgiving input timing
- **Coyote time** (150ms) — Grace period for late jumps
- **Clear visual feedback** — Screen shake on hit, visual indicators for all actions
- **Fast restarts** — Minimize friction between attempts

## Visual Style
- **Pixel art** aesthetic with clean, readable sprites
- **Color-coded worlds** — Each world has distinct palette and atmosphere
- **Two-tier sprite system** — Custom pixel art for key obstacles, Kenney CC0 fallbacks with color tinting for others

## Audio Guidelines
- **Procedural SFX** — Generated sound effects for game actions
- **3 audio buses** — Master, Music, SFX (independently toggleable)
- **Music per world** — Each world should have its own track (currently 1 track total)

## Performance Targets
- **Smooth 60fps** on mid-range mobile devices
- **Object pooling** for all frequently spawned objects (~50 pre-instantiated)
- **Minimal load times** — Instant level starts
