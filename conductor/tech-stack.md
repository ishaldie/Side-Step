# Tech Stack — Sidestep

## Engine
- **Godot 4.5.1** (GL Compatibility rendering mode)
- **Editor:** `Sidestep/_tools/Godot_v4.5.1-stable_win64.exe`

## Language
- **GDScript** — Godot's built-in scripting language

## Architecture
- **9 Autoload Singletons** — Global state management (`autoload/`)
- **16 Scene Scripts** — Scene-specific logic (`scripts/`)
- **13 Scene Files** — `.tscn` files (`scenes/`)
- **State Machine** — Player controller with 7 states
- **Event Bus** — Signal-based decoupled communication
- **Object Pooling** — Pre-instantiated obstacles/coins for performance

## Testing
- **Framework:** GUT (Godot Unit Testing) via `addons/gut/`
- **Test runner:** `test/run_tests.tscn`
- **Coverage:** 86 tests across 4 files (3 unit + 1 integration)
- **Test location:** `test/unit/` and `test/integration/`

## Security
- **Save encryption:** AES-256-CBC
- **Checksum validation** on loaded save data
- **Range validation** on all loaded numeric values

## Assets
- **Character:** 16 sprites (4 shoe tiers x 4 poses)
- **Obstacles:** ~24 custom pixel art + Kenney CC0 fallbacks
- **Audio:** 1 OGG music track, procedural SFX, 3 buses
- **UI:** Custom logo, buttons, HUD panels

## CI/CD
- **GitHub Actions** — `.github/workflows/ci.yml`
- **No remote configured** — Local development only currently

## Version Control
- **Manual directory-based versioning** — Each version in its own folder
- **Archive:** Previous versions zipped in `_archive_versions/`
- **Current:** v2.7.7 in `sidestep_v2.7.7/sidestep_v2.7.7/`

## Target Platforms
- **iOS** (primary) — App Store submission planned
- **Android** (secondary)
- **Display:** Portrait 480x800, touch input with mouse emulation
