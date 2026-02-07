# Side Step 👟

A fast-paced dodging game with 5 worlds, 25 levels, and shoe upgrades!

## Features

- **Object Pooling** - Improved performance with reusable game objects
- **Input Buffering** - 100ms input buffer + 80ms coyote time for responsive jumping
- **Audio System** - Sound effects for jumps, coins, hits, and more
- **Screen Effects** - Screen shake and flash on impacts
- **Settings Menu** - Adjustable music/SFX volume
- **Save Versioning** - Future-proof save system with migration support
- **Quit Confirmation** - Prevents accidental level exits

## 🎮 How to Play

- **A/D** or **←/→** to move left/right
- **W/SPACE/↑** to jump
- Dodge obstacles and collect coins
- Reach the target score to complete each level
- Buy shoe upgrades for better abilities!

## 🌍 5 Worlds (25 Levels Total)

### World 1: Road 🛣️ (Difficulty 1.0 - 2.5)
*Busy city streets with traffic hazards*

| Level | Name | Difficulty | Obstacles |
|-------|------|------------|-----------|
| 1-1 | Suburban Street | 1.0 | Cones, potholes |
| 1-2 | School Zone | 1.4 | + Backpacks |
| 1-3 | Downtown | 1.8 | + Bikes, hydrants |
| 1-4 | Construction Zone | 2.2 | Barriers, toolboxes, beams |
| 1-5 | Highway | 2.5 | Tires, oil spills |

### World 2: Soccer Field ⚽ (Difficulty 2.0 - 3.5)
*Dodge balls and players on the pitch*

| Level | Name | Difficulty | Obstacles |
|-------|------|------------|-----------|
| 2-1 | Practice Field | 2.0 | Soccer balls, cones |
| 2-2 | Youth League | 2.4 | + Sliding players |
| 2-3 | Club Match | 2.8 | + Goalkeepers |
| 2-4 | Championship | 3.2 | + Referees, flying balls |
| 2-5 | World Cup Final | 3.5 | + Confetti cannons |

### World 3: Beach 🏖️ (Difficulty 3.0 - 4.5)
*Sun, sand, and seaside obstacles*

| Level | Name | Difficulty | Obstacles |
|-------|------|------------|-----------|
| 3-1 | Quiet Cove | 3.0 | Sandcastles, beach balls |
| 3-2 | Tourist Beach | 3.4 | + Umbrellas, crabs |
| 3-3 | Tide Pools | 3.8 | Jellyfish, slippery rocks |
| 3-4 | Surf Zone | 4.2 | Surfboards, waves, surfers |
| 3-5 | Storm Surge | 4.5 | Big waves, flying debris |

### World 4: Underwater 🌊 (Difficulty 4.0 - 5.5)
*Dive deep into the ocean depths*

| Level | Name | Difficulty | Obstacles |
|-------|------|------------|-----------|
| 4-1 | Shallow Reef | 4.0 | Coral, small fish |
| 4-2 | Kelp Forest | 4.4 | Kelp, sea turtles, urchins |
| 4-3 | Shipwreck | 4.8 | Anchors, sharks, barrels |
| 4-4 | Deep Sea | 5.2 | Anglerfish, giant squid |
| 4-5 | Mariana Trench | 5.5 | Ancient creatures, crushing pressure |

### World 5: Volcano 🌋 (Difficulty 5.0 - 6.5)
*Escape the erupting inferno!*

| Level | Name | Difficulty | Obstacles |
|-------|------|------------|-----------|
| 5-1 | Volcanic Trail | 5.0 | Steam vents, hot rocks |
| 5-2 | Lava Fields | 5.4 | Lava pools, fire geysers |
| 5-3 | Magma Chamber | 5.8 | Stalactites, fire walls |
| 5-4 | Eruption | 6.2 | Lava bombs, pyroclastic flow |
| 5-5 | Caldera Escape | 6.5 | Meteors, fire tornadoes |

## 👟 Shoe Progression

| Shoe | Cost | Speed | Jump | Special Ability |
|------|------|-------|------|-----------------|
| 🦶 Barefoot | Free | 220 | 480 | None |
| 🩴 Flip Flops | 500 | 300 | 520 | Basic protection |
| 👟 Running Shoes | 1,500 | 400 | 560 | **Dash** ability |
| 👟✨ Winged Shoes | 4,000 | 480 | 600 | **Double Jump** + Dash |

## 🔓 Unlock Requirements

| World | Requirement |
|-------|-------------|
| Road | Always unlocked |
| Soccer Field | 8 stars |
| Beach | 16 stars |
| Underwater | 24 stars |
| Volcano | 32 stars |

## 🚀 Setup Instructions

1. Download and install [Godot 4.5+](https://godotengine.org/download)
2. Open Godot and click **Import**
3. Navigate to this folder and select `project.godot`
4. Click **Import & Edit**
5. Press **F5** to play!

## 📁 Project Structure

```
sidestep/
├── project.godot
├── autoload/
│   ├── game_manager.gd      # Game state, worlds, levels, save/load
│   ├── object_pool.gd       # Object pooling for obstacles/coins
│   ├── audio_manager.gd     # Sound effects and music
│   ├── screen_effects.gd    # Screen shake and visual feedback
│   ├── event_bus.gd         # Decoupled signal-based communication
│   ├── ad_manager.gd        # Ad integration framework
│   ├── analytics.gd         # Analytics tracking
│   └── tutorial_manager.gd  # Tutorial system
├── scenes/
│   ├── main_menu.tscn
│   ├── settings.tscn        # NEW: Audio settings
│   ├── world_select.tscn
│   ├── level_select.tscn
│   ├── shop.tscn
│   ├── game.tscn
│   ├── level_complete.tscn
│   ├── game_over.tscn
│   ├── victory.tscn
│   ├── player.tscn
│   ├── obstacle.tscn
│   └── coin.tscn
└── scripts/
    └── [matching .gd files]
```

## 🎯 Difficulty Scale

The difficulty rating (1.0 - 6.5) affects:
- **Obstacle Speed**: Higher = faster obstacles
- **Spawn Interval**: Lower = more frequent obstacles
- **Target Score**: Higher = longer level
- **Coin Chance**: Varies per level

## 💰 Economy

- Complete levels to earn coins
- Dying = keep half your collected coins
- Save up for shoe upgrades
- Better shoes make harder levels easier!

## 🎮 Controls

| Input | Action |
|-------|--------|
| A / ← | Move left |
| D / → | Move right |
| W / ↑ / Space | Jump |
| Escape | Pause |

## 📱 Mobile Ready

Touch controls work automatically - tap to jump!

---

Good luck reaching the Caldera! 🌋👟
