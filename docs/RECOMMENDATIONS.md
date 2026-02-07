# 🏗️ Architecture & Improvement Recommendations

## Table of Contents
1. [Architecture Improvements](#-architecture-improvements)
2. [Error Handling Improvements](#-error-handling-improvements)
3. [Type Safety Improvements](#-type-safety-improvements)
4. [Adding Ads (Monetization)](#-adding-ads-monetization)

---

# 🏗️ Architecture Improvements

## 1. Split GameManager into Focused Services

**Current Problem:** GameManager has 34 functions handling state, navigation, persistence, AND data access.

**Recommended Split:**

```
autoload/
├── game_state.gd      # Score, coins, session state
├── progress_manager.gd # World/level unlocks, completion tracking
├── save_manager.gd    # Persistence (save/load)
├── scene_manager.gd   # Navigation with transitions
└── game_data.gd       # Static data (WORLDS, SHOES, configs)
```

### game_state.gd (Session State)
```gdscript
extends Node
class_name GameStateManager

signal score_changed(new_score: int)
signal coins_changed(new_coins: int)

var score: int = 0
var coins: int = 0
var current_world_index: int = 0
var current_level_index: int = 0

func reset_session() -> void:
    score = 0
    coins = 0

func add_score(points: int) -> void:
    score += points
    score_changed.emit(score)

func collect_coin(value: int = 1) -> void:
    coins += value
    add_score(value * GameData.COIN_SCORE_MULTIPLIER)
    coins_changed.emit(coins)
```

### scene_manager.gd (Navigation with Transitions)
```gdscript
extends Node
class_name SceneManagerService

signal scene_changing(from: String, to: String)
signal scene_changed(scene_name: String)

var _current_scene: String = ""
var _is_transitioning: bool = false

func go_to(scene_path: String, with_fade: bool = true) -> void:
    if _is_transitioning:
        return
    
    _is_transitioning = true
    scene_changing.emit(_current_scene, scene_path)
    
    if with_fade:
        await ScreenEffects.fade_out(0.2)
    
    get_tree().change_scene_to_file(scene_path)
    _current_scene = scene_path
    
    if with_fade:
        await ScreenEffects.fade_in(0.2)
    
    _is_transitioning = false
    scene_changed.emit(scene_path)
```

### save_manager.gd (Persistence)
```gdscript
extends Node
class_name SaveManagerService

const SAVE_PATH: String = "user://sidestep_save.cfg"
const SAVE_VERSION: int = 1

signal save_completed(success: bool)
signal load_completed(success: bool)

func save_game() -> Error:
    var config := ConfigFile.new()
    # ... save logic
    var err := config.save(SAVE_PATH)
    save_completed.emit(err == OK)
    return err

func load_game() -> Error:
    var config := ConfigFile.new()
    var err := config.load(SAVE_PATH)
    if err != OK:
        load_completed.emit(false)
        return err
    # ... load logic
    load_completed.emit(true)
    return OK
```

## 2. Use Resource Files for Game Data

**Current:** Data is hardcoded in GDScript arrays/dictionaries.

**Better:** Use Godot Resource files for data-driven design.

### world_data.gd (Custom Resource)
```gdscript
extends Resource
class_name WorldData

@export var name: String
@export var icon: String
@export var description: String
@export var bg_color: Color
@export var ground_color: Color
@export var unlock_requirement: int
@export var levels: Array[LevelData]
```

### level_data.gd
```gdscript
extends Resource
class_name LevelData

@export var name: String
@export var description: String
@export var obstacles: Array[String]
@export var obstacle_speed: float
@export var spawn_interval: float
@export var target_score: int
@export_range(0.0, 1.0) var coin_chance: float
@export_range(1, 10) var difficulty: int
```

**Benefits:**
- Edit data in Godot Inspector (no code changes)
- Designers can tweak without programmers
- Easier to create DLC/expansions
- Type-safe at compile time

## 3. Event Bus Pattern

**Current:** Scripts directly call autoloads (`GameManager.add_score()`).

**Better:** Decouple with an event bus.

### event_bus.gd
```gdscript
extends Node

# Game events
signal coin_collected(value: int, position: Vector2)
signal obstacle_hit(obstacle_type: String)
signal player_died(position: Vector2)
signal level_completed(world: int, level: int, score: int)

# UI events
signal show_popup(message: String, duration: float)
signal shake_camera(intensity: float)
```

**Usage:**
```gdscript
# In coin.gd (publisher)
EventBus.coin_collected.emit(value, global_position)

# In game_state.gd (subscriber)
func _ready():
    EventBus.coin_collected.connect(_on_coin_collected)

func _on_coin_collected(value: int, _pos: Vector2) -> void:
    collect_coin(value)

# In particle_manager.gd (another subscriber)
func _ready():
    EventBus.coin_collected.connect(_on_coin_collected)

func _on_coin_collected(_value: int, pos: Vector2) -> void:
    spawn_coin_particles(pos)
```

**Benefits:**
- Components don't need to know about each other
- Easy to add new features (analytics, achievements) without touching existing code
- Better testability (can mock EventBus)

---

# 🛡️ Error Handling Improvements

## 1. Result Type Pattern

**Current:** Functions return bool or fail silently.

**Better:** Use a Result type for explicit error handling.

### result.gd
```gdscript
class_name Result
extends RefCounted

var success: bool
var value  # Any type
var error: String

static func ok(val = null) -> Result:
    var r := Result.new()
    r.success = true
    r.value = val
    return r

static func err(message: String) -> Result:
    var r := Result.new()
    r.success = false
    r.error = message
    return r

func unwrap():
    assert(success, "Unwrapped error result: " + error)
    return value

func unwrap_or(default):
    return value if success else default
```

**Usage:**
```gdscript
func purchase_shoe(shoe_index: int) -> Result:
    if shoe_index < 0 or shoe_index >= SHOES.size():
        return Result.err("Invalid shoe index: %d" % shoe_index)
    
    if unlocked_shoes[shoe_index]:
        return Result.err("Shoe already owned")
    
    var cost: int = SHOES[shoe_index].cost
    if total_coins < cost:
        return Result.err("Insufficient coins: need %d, have %d" % [cost, total_coins])
    
    total_coins -= cost
    unlocked_shoes[shoe_index] = true
    return Result.ok(SHOES[shoe_index])

# Caller
var result := GameManager.purchase_shoe(2)
if result.success:
    print("Purchased: ", result.value.name)
else:
    print("Failed: ", result.error)
```

## 2. Defensive Dictionary Access

**Current:**
```gdscript
var speed = config.obstacle_speed  # Crashes if key missing
```

**Better:**
```gdscript
func get_config_value(config: Dictionary, key: String, default = null):
    if not config.has(key):
        push_warning("Config missing key: %s" % key)
        return default
    return config[key]

# Or use .get() consistently
var speed: float = config.get("obstacle_speed", 200.0)
```

## 3. Validation Layer

### validators.gd
```gdscript
class_name Validators
extends RefCounted

static func validate_world_index(index: int) -> Result:
    if index < 0:
        return Result.err("World index cannot be negative")
    if index >= GameManager.WORLDS_COUNT:
        return Result.err("World index %d exceeds max %d" % [index, GameManager.WORLDS_COUNT - 1])
    return Result.ok(index)

static func validate_level_index(index: int) -> Result:
    if index < 0:
        return Result.err("Level index cannot be negative")
    if index >= GameManager.LEVELS_PER_WORLD:
        return Result.err("Level index %d exceeds max %d" % [index, GameManager.LEVELS_PER_WORLD - 1])
    return Result.ok(index)

static func validate_shoe_index(index: int) -> Result:
    if index < 0 or index >= GameManager.SHOES.size():
        return Result.err("Invalid shoe index: %d" % index)
    return Result.ok(index)
```

## 4. Centralized Error Logging

### error_logger.gd
```gdscript
extends Node

enum Severity { DEBUG, INFO, WARNING, ERROR, CRITICAL }

const LOG_PATH: String = "user://game_log.txt"
var _log_file: FileAccess

func _ready() -> void:
    _log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)

func log(severity: Severity, category: String, message: String) -> void:
    var timestamp := Time.get_datetime_string_from_system()
    var severity_str := Severity.keys()[severity]
    var line := "[%s] [%s] [%s] %s" % [timestamp, severity_str, category, message]
    
    print(line)
    if _log_file:
        _log_file.store_line(line)
    
    if severity >= Severity.ERROR:
        push_error(line)

func debug(category: String, message: String) -> void:
    log(Severity.DEBUG, category, message)

func error(category: String, message: String) -> void:
    log(Severity.ERROR, category, message)
```

---

# 🔒 Type Safety Improvements

## 1. Typed Dictionaries → Custom Classes

**Current:**
```gdscript
const SHOES: Array[Dictionary] = [
    {"type": 0, "name": "Barefoot", ...}
]
# No compile-time safety, can typo keys
```

**Better:**
```gdscript
class_name ShoeData
extends RefCounted

var type: int
var name: String
var icon: String
var description: String
var cost: int
var speed: float
var jump_force: float
var dash: bool
var double_jump: bool

func _init(p_type: int, p_name: String, p_icon: String, p_desc: String,
           p_cost: int, p_speed: float, p_jump: float, p_dash: bool, p_double: bool) -> void:
    type = p_type
    name = p_name
    icon = p_icon
    description = p_desc
    cost = p_cost
    speed = p_speed
    jump_force = p_jump
    dash = p_dash
    double_jump = p_double

# Usage
const SHOES: Array[ShoeData] = [
    ShoeData.new(0, "Barefoot", "🦶", "...", 0, 300.0, 500.0, false, false),
]

# Now IDE autocompletes: shoe.name, shoe.cost, etc.
```

## 2. Enums for String Constants

**Current:**
```gdscript
var obs_type: String = obstacles[randi() % obstacles.size()]
_is_flying_obstacle(obs_type)  # String comparison
```

**Better:**
```gdscript
enum ObstacleType {
    CONE, POTHOLE, BACKPACK, BIKE, HYDRANT,
    SOCCER_BALL, WATER_BOTTLE, SLIDING_PLAYER,
    # ... etc
}

func _is_flying_obstacle(obs_type: ObstacleType) -> bool:
    return obs_type in FLYING_OBSTACLES
```

## 3. Strict Null Checks

**Current:**
```gdscript
var player = $Player
player.hit_obstacle()  # Crashes if Player missing
```

**Better:**
```gdscript
@onready var _player: Player = $Player as Player

func _ready() -> void:
    assert(_player != null, "Player node not found!")

func _on_obstacle_hit() -> void:
    if _player:
        _player.hit_obstacle()
    else:
        ErrorLogger.error("Game", "Player reference is null")
```

## 4. Signal Type Safety (Godot 4.x)

```gdscript
# Typed signals
signal score_changed(new_score: int)
signal level_completed(world_index: int, level_index: int)
signal position_updated(new_position: Vector2)

# Compiler will warn if you emit with wrong types
score_changed.emit("hello")  # Warning: expected int
```

---

# 💰 Adding Ads (Monetization)

## Overview

For Godot mobile games, the main ad SDKs are:
1. **Google AdMob** (most popular, best fill rates)
2. **Unity Ads** (good for games)
3. **AppLovin/MAX** (good mediation)
4. **Meta Audience Network**

I recommend **AdMob** for simplicity or **AppLovin MAX** for mediation (higher revenue).

## Step 1: Install Godot AdMob Plugin

### Option A: GodotAdMob Plugin (Recommended)

```bash
# Clone the plugin
git clone https://github.com/poing-studios/godot-admob-plugin

# Or download from Godot Asset Library
# Search: "AdMob"
```

1. Copy `addons/admob/` to your project
2. Enable in Project Settings → Plugins
3. Download the Android/iOS export templates with AdMob support

### Option B: Poing Studios Plugin (More Features)

Download from: https://github.com/poing-studios/godot-admob-plugin

## Step 2: Configure AdMob Account

1. Go to https://admob.google.com
2. Create an account (needs Google account)
3. Add your app (even before publishing - use test mode)
4. Create Ad Units:
   - **Banner** (always visible, low revenue)
   - **Interstitial** (full screen between levels)
   - **Rewarded** (user opts in for reward - HIGHEST revenue)

5. Copy your Ad Unit IDs:
   ```
   Banner:       ca-app-pub-XXXXXXX/YYYYYYY
   Interstitial: ca-app-pub-XXXXXXX/ZZZZZZZ
   Rewarded:     ca-app-pub-XXXXXXX/WWWWWWW
   ```

## Step 3: Create Ad Manager

### autoload/ad_manager.gd
```gdscript
## AdManager Autoload
## Handles all advertising functionality
extends Node

# =============================================================================
# CONFIGURATION
# =============================================================================

# Use test IDs during development!
const TEST_MODE: bool = true

# Test Ad Unit IDs (safe for development)
const TEST_BANNER_ID: String = "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"

# Production Ad Unit IDs (replace with yours!)
const PROD_BANNER_ID: String = "ca-app-pub-YOUR_ID/BANNER_ID"
const PROD_INTERSTITIAL_ID: String = "ca-app-pub-YOUR_ID/INTERSTITIAL_ID"
const PROD_REWARDED_ID: String = "ca-app-pub-YOUR_ID/REWARDED_ID"

# =============================================================================
# SIGNALS
# =============================================================================

signal interstitial_closed
signal rewarded_ad_completed(reward_type: String, reward_amount: int)
signal rewarded_ad_failed
signal ad_failed_to_load(ad_type: String)

# =============================================================================
# STATE
# =============================================================================

var _admob: Node = null
var _is_initialized: bool = false
var _interstitial_loaded: bool = false
var _rewarded_loaded: bool = false
var _games_since_last_ad: int = 0

const GAMES_BETWEEN_ADS: int = 3  # Show interstitial every 3 games

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# AdMob plugin creates a singleton
	if Engine.has_singleton("AdMob"):
		_admob = Engine.get_singleton("AdMob")
		_initialize_admob()
	else:
		push_warning("AdMob singleton not found - ads disabled")


func _initialize_admob() -> void:
	if not _admob:
		return
	
	var config := {
		"is_test": TEST_MODE,
		"is_for_child_directed_treatment": false,
		"max_ad_content_rating": "G",  # G, PG, T, MA
		"is_real": not TEST_MODE
	}
	
	_admob.initialize(config)
	_is_initialized = true
	
	# Connect signals
	_admob.connect("initialization_completed", _on_init_complete)
	_admob.connect("interstitial_loaded", _on_interstitial_loaded)
	_admob.connect("interstitial_closed", _on_interstitial_closed)
	_admob.connect("interstitial_failed_to_load", _on_interstitial_failed)
	_admob.connect("rewarded_ad_loaded", _on_rewarded_loaded)
	_admob.connect("rewarded_ad_earned_reward", _on_reward_earned)
	_admob.connect("rewarded_ad_closed", _on_rewarded_closed)
	_admob.connect("rewarded_ad_failed_to_load", _on_rewarded_failed)
	
	print("[AdManager] Initialized (test_mode=%s)" % TEST_MODE)


func _on_init_complete(_status: int) -> void:
	# Preload ads
	load_interstitial()
	load_rewarded()

# =============================================================================
# BANNER ADS
# =============================================================================

func show_banner(position: String = "BOTTOM") -> void:
	if not _admob:
		return
	
	var ad_id := TEST_BANNER_ID if TEST_MODE else PROD_BANNER_ID
	_admob.load_banner({
		"ad_unit_id": ad_id,
		"position": position,  # TOP, BOTTOM
		"size": "BANNER"  # BANNER, LARGE_BANNER, FULL_BANNER
	})


func hide_banner() -> void:
	if _admob:
		_admob.hide_banner()


func destroy_banner() -> void:
	if _admob:
		_admob.destroy_banner()

# =============================================================================
# INTERSTITIAL ADS
# =============================================================================

func load_interstitial() -> void:
	if not _admob:
		return
	
	var ad_id := TEST_INTERSTITIAL_ID if TEST_MODE else PROD_INTERSTITIAL_ID
	_admob.load_interstitial(ad_id)


func show_interstitial() -> bool:
	if not _admob or not _interstitial_loaded:
		return false
	
	_admob.show_interstitial()
	return true


func show_interstitial_if_ready() -> void:
	"""Shows interstitial based on frequency cap."""
	_games_since_last_ad += 1
	
	if _games_since_last_ad >= GAMES_BETWEEN_ADS:
		if show_interstitial():
			_games_since_last_ad = 0


func _on_interstitial_loaded() -> void:
	_interstitial_loaded = true
	print("[AdManager] Interstitial loaded")


func _on_interstitial_closed() -> void:
	_interstitial_loaded = false
	interstitial_closed.emit()
	# Preload next one
	load_interstitial()


func _on_interstitial_failed(_error_code: int) -> void:
	_interstitial_loaded = false
	ad_failed_to_load.emit("interstitial")

# =============================================================================
# REWARDED ADS
# =============================================================================

func load_rewarded() -> void:
	if not _admob:
		return
	
	var ad_id := TEST_REWARDED_ID if TEST_MODE else PROD_REWARDED_ID
	_admob.load_rewarded_ad(ad_id)


func show_rewarded() -> bool:
	if not _admob or not _rewarded_loaded:
		return false
	
	_admob.show_rewarded_ad()
	return true


func is_rewarded_ready() -> bool:
	return _rewarded_loaded


func _on_rewarded_loaded() -> void:
	_rewarded_loaded = true
	print("[AdManager] Rewarded ad loaded")


func _on_reward_earned(reward_type: String, reward_amount: int) -> void:
	print("[AdManager] Reward earned: %s x%d" % [reward_type, reward_amount])
	rewarded_ad_completed.emit(reward_type, reward_amount)


func _on_rewarded_closed() -> void:
	_rewarded_loaded = false
	# Preload next one
	load_rewarded()


func _on_rewarded_failed(_error_code: int) -> void:
	_rewarded_loaded = false
	rewarded_ad_failed.emit()
	ad_failed_to_load.emit("rewarded")
```

## Step 4: Integration Points

### In game_over.gd (Interstitial on Death)
```gdscript
func _ready() -> void:
	# ... existing code ...
	
	# Show interstitial every few deaths
	AdManager.show_interstitial_if_ready()


# Optional: "Watch ad to continue" button
func _on_continue_button_pressed() -> void:
	if AdManager.is_rewarded_ready():
		AdManager.rewarded_ad_completed.connect(_on_ad_reward, CONNECT_ONE_SHOT)
		AdManager.show_rewarded()
	else:
		$ContinueButton.text = "Ad not ready"


func _on_ad_reward(_type: String, _amount: int) -> void:
	# Give player another chance
	GameManager.score = int(GameManager.score * 0.5)  # Keep half score
	GameManager.restart_level()
```

### In level_complete.gd (Rewarded for Bonus)
```gdscript
func _ready() -> void:
	# ... existing code ...
	
	# Show "Double Coins" button if rewarded ad is ready
	if AdManager.is_rewarded_ready():
		$DoubleCoinsButton.show()
	else:
		$DoubleCoinsButton.hide()


func _on_double_coins_pressed() -> void:
	AdManager.rewarded_ad_completed.connect(_on_double_reward, CONNECT_ONE_SHOT)
	AdManager.show_rewarded()


func _on_double_reward(_type: String, _amount: int) -> void:
	GameManager.total_coins += GameManager.coins  # Double the coins
	_coins_label.text = "Coins: +%d (DOUBLED!)" % (GameManager.coins * 2)
	$DoubleCoinsButton.hide()
```

### In main_menu.gd (Banner Ad)
```gdscript
func _ready() -> void:
	# ... existing code ...
	
	# Show banner on main menu
	AdManager.show_banner("BOTTOM")


func _on_play_button_pressed() -> void:
	# Hide banner when entering game
	AdManager.hide_banner()
	GameManager.go_to_world_select()
```

## Step 5: Export Configuration

### Android Setup

1. **Get SHA-1 fingerprint:**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **Add to AndroidManifest.xml:**
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
   ```

3. **Enable in Export Settings:**
   - Project → Export → Android
   - Custom Build → Enable
   - Permissions: INTERNET, ACCESS_NETWORK_STATE

### iOS Setup

1. **Add to Info.plist:**
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
   <key>SKAdNetworkItems</key>
   <array>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>cstr6suwn9.skadnetwork</string>
       </dict>
   </array>
   ```

2. **Add App Tracking Transparency (iOS 14+):**
   ```xml
   <key>NSUserTrackingUsageDescription</key>
   <string>This allows us to show you relevant ads.</string>
   ```

## Step 6: Ad Placement Best Practices

| Ad Type | When to Show | Frequency | Revenue |
|---------|--------------|-----------|---------|
| **Banner** | Main menu, shop | Always visible | Low |
| **Interstitial** | After death, level complete | Every 2-3 games | Medium |
| **Rewarded** | Double coins, continue, free coins | On demand | High |

### DO:
- ✅ Show interstitials at natural breaks (death, level end)
- ✅ Always preload the next ad
- ✅ Give real rewards for watching rewarded ads
- ✅ Test with TEST_MODE = true first
- ✅ Add frequency caps (don't spam ads)

### DON'T:
- ❌ Show ads during gameplay
- ❌ Show interstitial on first game
- ❌ Force users to watch rewarded ads
- ❌ Use production IDs during development (ban risk!)
- ❌ Click your own ads (instant ban)

## Step 7: Testing Checklist

- [ ] TEST_MODE = true during development
- [ ] Interstitial shows and closes properly
- [ ] Rewarded ad gives reward on completion
- [ ] Ads don't show during gameplay
- [ ] App doesn't crash if ad fails to load
- [ ] Banner doesn't overlap UI elements
- [ ] Frequency cap works correctly
- [ ] Switch to production IDs before release

## Revenue Expectations

| Game Downloads | Daily Active Users | Monthly Revenue |
|----------------|-------------------|-----------------|
| 1,000 | ~100 | $5-20 |
| 10,000 | ~1,000 | $50-200 |
| 100,000 | ~10,000 | $500-2,000 |
| 1,000,000 | ~100,000 | $5,000-20,000 |

*Estimates based on ~$1-5 eCPM for casual games*

---

## Summary

### Priority Order

1. **High Impact, Low Effort:**
   - Add Result type for error handling
   - Use .get() for all dictionary access
   - Add EventBus for decoupling

2. **High Impact, Medium Effort:**
   - Split GameManager into services
   - Add AdManager for monetization

3. **Medium Impact, High Effort:**
   - Convert to Resource files
   - Convert dictionaries to typed classes
   - Full enum conversion for strings
