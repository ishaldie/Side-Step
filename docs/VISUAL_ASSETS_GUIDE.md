# Side Step - Visual Assets Guide

## Current State: Procedural Graphics

The game currently uses **procedurally generated graphics** created entirely in code using Godot's `Polygon2D` nodes. While functional for gameplay and testing, these are placeholder visuals that need to be replaced with proper art assets before App Store submission.

---

## What "Procedural Graphics" Means

Instead of image files (.png, .jpg, .svg), all visuals are created by defining polygon vertices in code:

```gdscript
# Example: Creating a cone obstacle
var cone := Polygon2D.new()
cone.polygon = PackedVector2Array([
    Vector2(0, -half_h),      # Top point
    Vector2(-half_w, half_h), # Bottom left
    Vector2(half_w, half_h)   # Bottom right
])
cone.color = Color(1.0, 0.5, 0.0)  # Orange
```

This results in simple geometric shapes with flat colors - functional but not visually appealing.

---

## Current Visual Implementation

### Player Character (`scripts/player.gd`)

**Current:** A shoe-shaped polygon with color variations per shoe type

```
┌─────────────────────────────────────────┐
│  BAREFOOT (Brown/Tan)                   │
│  ┌───────────────┐                      │
│  │   ▄▄▄▄▄▄▄    │  Simple foot shape   │
│  │  █████████   │  with toes           │
│  └───────────────┘                      │
├─────────────────────────────────────────┤
│  FLIP FLOPS (Blue)                      │
│  ┌───────────────┐                      │
│  │   ▄▄▄▄▄▄▄    │  Flat sandal shape   │
│  │  █████████   │  with straps         │
│  └───────────────┘                      │
├─────────────────────────────────────────┤
│  RUNNING SHOES (Red/White)              │
│  ┌───────────────┐                      │
│  │  ╱▀▀▀▀▀▀▀╲   │  Athletic shoe       │
│  │ █████████████ │  with swoosh detail │
│  └───────────────┘                      │
├─────────────────────────────────────────┤
│  WINGED SHOES (Gold + Wings)            │
│  ┌───────────────┐                      │
│  │≋╱▀▀▀▀▀▀▀╲≋  │  Golden shoe with    │
│  │ █████████████ │  animated wings      │
│  └───────────────┘                      │
└─────────────────────────────────────────┘
```

**Needed:** Animated sprite sheets with:
- Idle pose
- Running animation (4-8 frames)
- Jump pose (ascending/descending)
- Duck pose
- Dash effect
- Death animation
- 4 different shoe designs

### Obstacles (`scripts/obstacle.gd`)

**65+ obstacle types** currently rendered as colored polygons:

| Obstacle | Current | Needed |
|----------|---------|--------|
| Cone | Orange triangle + white stripes | 3D-style traffic cone |
| Pothole | Dark ellipse | Cracked asphalt texture |
| Backpack | Rectangle + straps | Cute character backpack |
| Bike | Circles + frame | Cartoon bicycle |
| Tire | Black circle + treads | Bouncing rubber tire |
| Soccer Ball | White circle + pentagons | Spinning soccer ball |
| Crab | Red circle + claws | Animated crab character |
| Shark | Gray triangle + fin | Menacing shark sprite |
| Meteor | Orange circle + flames | Flaming rock with trail |
| ...and 55+ more | Basic shapes | Detailed sprites |

### Coins (`scripts/coin.gd`)

**Current:** Yellow circle with a "C" letter
**Needed:** Shiny animated coin with:
- Spinning animation
- Sparkle effects
- Collection particle burst

### Backgrounds (5 Worlds)

**Current:** Solid `ColorRect` with gradient

| World | Current | Needed |
|-------|---------|--------|
| Road | Gray/Blue solid | City skyline, buildings, clouds |
| Soccer | Green/Blue solid | Stadium, grass texture, crowd |
| Beach | Tan/Blue solid | Ocean waves, palm trees, sand |
| Underwater | Deep blue solid | Coral reef, bubbles, light rays |
| Volcano | Red/Orange solid | Lava flows, rocks, ash clouds |

Each world needs:
- Background layer (static)
- Midground layer (slow parallax)
- Foreground decorations (fast parallax)
- Ground texture

### UI Elements

**Current:** Default Godot buttons and labels
**Needed:**
- Custom button styles (normal, pressed, disabled)
- Panel backgrounds
- Progress bar skins
- Star icons (empty, filled)
- Coin icon
- Shoe icons for shop
- World unlock badges

### App Store Assets

**Missing entirely:**
- App icon (1024x1024)
- Launch screen / splash
- Screenshots (multiple device sizes)
- Feature graphic

---

## Why This Can't Be Code-Generated

1. **Artistic Quality:** Good game art requires human creativity, style consistency, and visual appeal that algorithms cannot replicate

2. **Animation:** Smooth character animations need hand-crafted keyframes or professional rigging

3. **Personality:** The game needs a cohesive visual identity - cute? realistic? pixel art? - that defines the brand

4. **Player Appeal:** App Store users judge games by screenshots in milliseconds; procedural shapes won't compete

5. **Platform Requirements:** Apple specifically reviews apps for "minimum functionality" which includes visual polish

---

## Asset Requirements Specification

### Sprite Format
- **Format:** PNG with transparency
- **Resolution:** 2x for Retina displays
- **Style:** Recommend cartoon/casual style for broad appeal

### Player Sprites
```
Size: 64x64 pixels (base)
Animations needed:
  - idle.png (1-2 frames)
  - run.png (6-8 frames)  
  - jump.png (3 frames: launch, peak, fall)
  - duck.png (1-2 frames)
  - dash.png (2-3 frames + blur effect)
  - death.png (4-6 frames)
  
Variants: 4 shoe types × all animations = ~100 frames
```

### Obstacle Sprites
```
Size: Varies (32x32 to 96x96)
Per obstacle: 1-4 frames for animation
Total: 65+ obstacles × avg 2 frames = ~150 sprites
```

### Background Layers
```
Size: 1920x1080 (tileable horizontally)
Per world: 3 layers (back, mid, fore)
Total: 5 worlds × 3 layers = 15 background images
```

### UI Kit
```
Buttons: 3 states × 3 sizes = 9 sprites
Panels: 4-5 variants
Icons: ~20 (coins, stars, shoes, settings, etc.)
Total: ~40 UI elements
```

---

## Options for Obtaining Art Assets

### Option 1: Hire a 2D Artist
**Cost:** $500 - $3,000+
**Timeline:** 2-6 weeks
**Pros:** Custom, unique, exactly what you want
**Cons:** Most expensive, requires art direction

**Where to find:**
- Fiverr (budget)
- Upwork (mid-range)
- ArtStation (professional)

### Option 2: Purchase Asset Packs
**Cost:** $20 - $200
**Timeline:** Immediate
**Pros:** Cheap, fast, professional quality
**Cons:** Not unique, may need modification

**Recommended packs:**
- Kenney.nl (free/donation, excellent quality)
- itch.io game assets
- Unity Asset Store (many work with Godot)
- GameDev Market

### Option 3: AI-Generated Art (with refinement)
**Cost:** $0 - $50/month for tools
**Timeline:** 1-2 weeks
**Pros:** Fast iteration, low cost
**Cons:** Inconsistent style, may need touch-up, licensing concerns

**Tools:**
- Midjourney / DALL-E for concepts
- Stable Diffusion for game sprites
- Requires artist cleanup for consistency

### Option 4: Hybrid Approach (Recommended)
1. Use free Kenney assets for placeholder upgrade
2. Generate concepts with AI
3. Hire artist for character/key visuals only
4. Use asset packs for backgrounds/UI

**Estimated cost:** $200 - $800
**Timeline:** 2-3 weeks

---

## Integration Guide

Once you have sprite assets, here's how to integrate them:

### 1. Create Sprite Folder Structure
```
res://assets/
  ├── sprites/
  │   ├── player/
  │   │   ├── barefoot/
  │   │   ├── flipflops/
  │   │   ├── running/
  │   │   └── winged/
  │   ├── obstacles/
  │   │   ├── road/
  │   │   ├── soccer/
  │   │   ├── beach/
  │   │   ├── underwater/
  │   │   └── volcano/
  │   └── coins/
  ├── backgrounds/
  │   ├── road/
  │   ├── soccer/
  │   └── ...
  └── ui/
      ├── buttons/
      ├── panels/
      └── icons/
```

### 2. Replace Polygon2D with Sprite2D

**Before (current):**
```gdscript
var sprite := Polygon2D.new()
sprite.polygon = PackedVector2Array([...])
sprite.color = Color.ORANGE
```

**After (with sprites):**
```gdscript
var sprite := AnimatedSprite2D.new()
sprite.sprite_frames = preload("res://assets/sprites/player/running/frames.tres")
sprite.play("run")
```

### 3. Update Scene Files

Convert `player.tscn` from:
```
Player (CharacterBody2D)
  └── Sprite (Polygon2D)  ← Current
```

To:
```
Player (CharacterBody2D)
  └── Sprite (AnimatedSprite2D)  ← With sprite sheets
```

---

## Minimum Viable Art (MVP)

If budget is extremely limited, prioritize:

1. **App Icon** - First impression, required
2. **Player character** - Most visible element
3. **Coins** - Satisfying collection feedback
4. **3-5 key obstacles** - Cones, barriers, balls
5. **Background for World 1** - First player experience

This "MVP art" approach could cost as little as $50-100 using asset packs + minimal custom work.

---

## Summary

| Category | Current | Needed | Priority |
|----------|---------|--------|----------|
| Player | Polygon shapes | Animated sprites | 🔴 Critical |
| Obstacles | Polygon shapes | Static/animated sprites | 🔴 Critical |
| Coins | Yellow circle | Animated coin | 🟡 High |
| Backgrounds | Solid colors | Layered parallax | 🟡 High |
| UI | Default Godot | Custom theme | 🟢 Medium |
| App Icon | None | 1024x1024 | 🔴 Critical |
| Screenshots | None | 5+ per device | 🔴 Critical |

**Bottom line:** The game mechanics are complete, but visual assets are the #1 blocker for App Store submission. Budget $200-1000 and 2-4 weeks for art production.
