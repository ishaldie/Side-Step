## GameManager Autoload
## Manages all persistent game state including worlds, levels, shoes, and save data.
## This is a singleton accessed via GameManager from any script.
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const GAME_VERSION: String = "2.8.0"

## TEST MODE - Automatically enabled in editor/debug builds, disabled in release exports.
## In debug: all content unlocked, tutorial resets each launch.
## In release: normal progression rules apply.
var TEST_MODE: bool = OS.is_debug_build()

const WORLDS_COUNT: int = 5
const LEVELS_PER_WORLD: int = 5
const TOTAL_LEVELS: int = WORLDS_COUNT * LEVELS_PER_WORLD
const SAVE_PATH: String = "user://sidestep_save.cfg"
const SAVE_PATH_ENCRYPTED: String = "user://sidestep_save.enc"
const SAVE_VERSION: int = 3  # Increment when save format changes (3 = encrypted)
## Save encryption key - derived at runtime to avoid plaintext in binary.
## This is anti-cheat, not security-critical. A determined user can still
## reverse-engineer it, but it won't show up in a simple strings search.
var SAVE_ENCRYPTION_KEY: String = _derive_save_key()
const DEATH_COIN_PENALTY: float = 0.5

# Star thresholds (percentage of coins collected)
const STAR_1_THRESHOLD: float = 0.70  # 70% coins = 1 star
const STAR_2_THRESHOLD: float = 0.85  # 85% coins = 2 stars
const STAR_3_THRESHOLD: float = 0.95  # 95% coins = 3 stars

# World unlock requirements (total stars needed)
const STARS_PER_WORLD_UNLOCK: int = 8  # World 2 = 8, World 3 = 16, etc.

# Scene paths as constants to avoid typos
const SCENE_GAME: String = "res://scenes/game.tscn"
const SCENE_MAIN_MENU: String = "res://scenes/main_menu.tscn"
const SCENE_WORLD_SELECT: String = "res://scenes/world_select.tscn"
const SCENE_LEVEL_SELECT: String = "res://scenes/level_select.tscn"
const SCENE_SHOP: String = "res://scenes/shop.tscn"
const SCENE_LEVEL_COMPLETE: String = "res://scenes/level_complete.tscn"
const SCENE_GAME_OVER: String = "res://scenes/game_over.tscn"
const SCENE_SETTINGS: String = "res://scenes/settings.tscn"
const SCENE_VICTORY: String = "res://scenes/victory.tscn"

# =============================================================================
# ENUMS
# =============================================================================

enum ShoeType { BAREFOOT, FLIP_FLOPS, RUNNING_SHOES, WINGED_SHOES }

# =============================================================================
# SIGNALS (for external listeners - UI reactivity, achievements, etc.)
# =============================================================================

signal coins_changed(new_coins: int)
signal distance_changed(new_distance: float)
signal level_completed(world_index: int, level_index: int)
signal shoe_purchased(shoe_type: int)
signal shoe_equipped(shoe_type: int)
signal stars_earned(stars: int)

# =============================================================================
# SHOE DATA
# =============================================================================

const SHOES: Array[Dictionary] = [
	{
		"type": ShoeType.BAREFOOT,
		"name": "Barefoot",
		"description": "Just your feet. Ouch!",
		"speed": 220.0,
		"jump_force": 480.0,
		"double_jump": false,
		"dash": false,
		"cost": 0,
		"icon": "🦶"
	},
	{
		"type": ShoeType.FLIP_FLOPS,
		"name": "Flip Flops",
		"description": "Basic protection. Flop flop flop!",
		"speed": 300.0,
		"jump_force": 520.0,
		"double_jump": false,
		"dash": false,
		"cost": 500,
		"icon": "🩴"
	},
	{
		"type": ShoeType.RUNNING_SHOES,
		"name": "Running Shoes",
		"description": "Now we're talking! Dash ability unlocked.",
		"speed": 400.0,
		"jump_force": 560.0,
		"double_jump": false,
		"dash": true,
		"cost": 1500,
		"icon": "👟"
	},
	{
		"type": ShoeType.WINGED_SHOES,
		"name": "Winged Shoes",
		"description": "Like Hermes! Double jump unlocked.",
		"speed": 480.0,
		"jump_force": 600.0,
		"double_jump": true,
		"dash": true,
		"cost": 4000,
		"icon": "👟✨"
	}
]

# =============================================================================
# WORLD DATA
# Levels use target_distance (pixels) instead of score
# Duration = target_distance / obstacle_speed
# =============================================================================

const WORLDS: Array[Dictionary] = [
	{
		"name": "Road", "icon": "🛣️", "description": "Busy city streets with traffic hazards",
		"bg_color": Color(0.55, 0.7, 0.85, 1.0), "ground_color": Color(0.3, 0.3, 0.32, 1.0),
		"sky_gradient_top": Color(0.4, 0.6, 0.9, 1.0), "sky_gradient_bottom": Color(0.7, 0.8, 0.95, 1.0),
		"decorations": ["building", "tree", "cloud", "lamppost"],
		"unlock_requirement": 0,  # First world always unlocked
		"levels": [
			{"name": "Suburban Street", "difficulty": 1.0, "obstacle_speed": 195.0, "spawn_interval": 2.2, "target_distance": 4500.0, "obstacles": ["cone", "pothole"], "coin_chance": 0.35, "description": "A quiet neighborhood road"},
			{"name": "School Zone", "difficulty": 1.4, "obstacle_speed": 221.0, "spawn_interval": 2.0, "target_distance": 5950.0, "obstacles": ["cone", "pothole", "backpack"], "coin_chance": 0.35, "description": "Watch for crossing guards!"},
			{"name": "Downtown", "difficulty": 1.8, "obstacle_speed": 247.0, "spawn_interval": 1.8, "target_distance": 7600.0, "obstacles": ["cone", "pothole", "bike", "hydrant"], "coin_chance": 0.3, "description": "City center hustle"},
			{"name": "Construction Zone", "difficulty": 2.2, "obstacle_speed": 273.0, "spawn_interval": 1.7, "target_distance": 9450.0, "obstacles": ["cone", "barrier", "toolbox", "beam"], "coin_chance": 0.3, "description": "Hard hats required!"},
			{"name": "Highway", "difficulty": 2.5, "obstacle_speed": 312.0, "spawn_interval": 1.5, "target_distance": 12000.0, "obstacles": ["cone", "tire", "oil_spill", "barrier"], "coin_chance": 0.25, "description": "High-speed danger zone"}
		]
	},
	{
		"name": "Soccer Field", "icon": "⚽", "description": "Dodge balls and players on the pitch",
		"bg_color": Color(0.5, 0.75, 0.95, 1.0), "ground_color": Color(0.25, 0.55, 0.3, 1.0),
		"sky_gradient_top": Color(0.35, 0.55, 0.85, 1.0), "sky_gradient_bottom": Color(0.6, 0.8, 0.95, 1.0),
		"decorations": ["stadium", "flag", "cloud", "scoreboard"],
		"unlock_requirement": 8,  # 8 stars needed
		"levels": [
			{"name": "Practice Field", "difficulty": 2.0, "obstacle_speed": 200.0, "spawn_interval": 1.9, "target_distance": 7000.0, "obstacles": ["soccer_ball", "cone", "water_bottle"], "coin_chance": 0.35, "description": "Warm-up session"},
			{"name": "Youth League", "difficulty": 2.4, "obstacle_speed": 220.0, "spawn_interval": 1.7, "target_distance": 8800.0, "obstacles": ["soccer_ball", "sliding_player", "cone", "goal_post"], "coin_chance": 0.35, "description": "Kids play rough!"},
			{"name": "Club Match", "difficulty": 2.8, "obstacle_speed": 245.0, "spawn_interval": 1.6, "target_distance": 11025.0, "obstacles": ["soccer_ball", "sliding_player", "goalkeeper", "corner_flag"], "coin_chance": 0.3, "description": "Semi-pro action"},
			{"name": "Championship", "difficulty": 3.2, "obstacle_speed": 270.0, "spawn_interval": 1.5, "target_distance": 13500.0, "obstacles": ["soccer_ball", "sliding_player", "goalkeeper", "referee", "flying_ball"], "coin_chance": 0.3, "description": "Title on the line!"},
			{"name": "International Final", "difficulty": 3.5, "obstacle_speed": 300.0, "spawn_interval": 1.35, "target_distance": 16500.0, "obstacles": ["soccer_ball", "sliding_player", "goalkeeper", "flying_ball", "confetti_cannon"], "coin_chance": 0.25, "description": "The biggest stage!"}
		]
	},
	{
		"name": "Beach", "icon": "🏖️", "description": "Sun, sand, and seaside obstacles",
		"bg_color": Color(0.4, 0.75, 0.95, 1.0), "ground_color": Color(0.95, 0.85, 0.6, 1.0),
		"sky_gradient_top": Color(0.3, 0.6, 0.9, 1.0), "sky_gradient_bottom": Color(0.85, 0.92, 1.0, 1.0),
		"decorations": ["palm_tree", "sun", "cloud", "seagull", "wave_bg"],
		"unlock_requirement": 16,  # 16 stars needed
		"levels": [
			{"name": "Quiet Cove", "difficulty": 3.0, "obstacle_speed": 230.0, "spawn_interval": 1.7, "target_distance": 9200.0, "obstacles": ["sandcastle", "beach_ball", "towel", "seashell"], "coin_chance": 0.4, "description": "A peaceful beach morning"},
			{"name": "Tourist Beach", "difficulty": 3.4, "obstacle_speed": 255.0, "spawn_interval": 1.55, "target_distance": 11475.0, "obstacles": ["sandcastle", "beach_ball", "umbrella", "cooler", "crab"], "coin_chance": 0.35, "description": "Crowded shoreline"},
			{"name": "Tide Pools", "difficulty": 3.8, "obstacle_speed": 280.0, "spawn_interval": 1.45, "target_distance": 14000.0, "obstacles": ["crab", "jellyfish", "seaweed", "slippery_rock", "tide_wave"], "coin_chance": 0.35, "description": "Slippery when wet!"},
			{"name": "Surf Zone", "difficulty": 4.2, "obstacle_speed": 310.0, "spawn_interval": 1.35, "target_distance": 17050.0, "obstacles": ["surfboard", "wave", "surfer", "jellyfish", "beach_ball"], "coin_chance": 0.3, "description": "Cowabunga dude!"},
			{"name": "Storm Surge", "difficulty": 4.5, "obstacle_speed": 340.0, "spawn_interval": 1.25, "target_distance": 20400.0, "obstacles": ["big_wave", "debris", "flying_umbrella", "crab", "jellyfish"], "coin_chance": 0.25, "description": "Beach evacuation!"}
		]
	},
	{
		"name": "Underwater", "icon": "🌊", "description": "Dive deep into the ocean depths",
		"bg_color": Color(0.05, 0.2, 0.4, 1.0), "ground_color": Color(0.1, 0.15, 0.25, 1.0),
		"sky_gradient_top": Color(0.02, 0.08, 0.2, 1.0), "sky_gradient_bottom": Color(0.1, 0.3, 0.5, 1.0),
		"decorations": ["bubble", "seaweed_bg", "light_ray", "distant_fish"],
		"unlock_requirement": 24,  # 24 stars needed
		"levels": [
			{"name": "Shallow Reef", "difficulty": 4.0, "obstacle_speed": 260.0, "spawn_interval": 1.55, "target_distance": 11700.0, "obstacles": ["coral", "small_fish", "seaweed", "clam"], "coin_chance": 0.4, "description": "Crystal clear waters"},
			{"name": "Kelp Forest", "difficulty": 4.4, "obstacle_speed": 290.0, "spawn_interval": 1.45, "target_distance": 14500.0, "obstacles": ["kelp", "sea_turtle", "school_of_fish", "urchin"], "coin_chance": 0.35, "description": "Dense underwater jungle"},
			{"name": "Shipwreck", "difficulty": 4.8, "obstacle_speed": 320.0, "spawn_interval": 1.35, "target_distance": 17600.0, "obstacles": ["anchor", "barrel", "shark", "treasure_chest", "chain"], "coin_chance": 0.35, "description": "Explore the wreckage"},
			{"name": "Deep Sea", "difficulty": 5.2, "obstacle_speed": 350.0, "spawn_interval": 1.25, "target_distance": 21000.0, "obstacles": ["anglerfish", "giant_squid", "pressure_vent", "bioluminescent"], "coin_chance": 0.3, "description": "Into the abyss"},
			{"name": "The Abyss", "difficulty": 5.5, "obstacle_speed": 385.0, "spawn_interval": 1.15, "target_distance": 25025.0, "obstacles": ["giant_squid", "anglerfish", "thermal_vent", "crushing_pressure", "ancient_creature"], "coin_chance": 0.25, "description": "The deepest depths of the ocean"}
		]
	},
	{
		"name": "Volcano", "icon": "🌋", "description": "Escape the erupting inferno!",
		"bg_color": Color(0.25, 0.08, 0.05, 1.0), "ground_color": Color(0.15, 0.08, 0.05, 1.0),
		"sky_gradient_top": Color(0.1, 0.02, 0.0, 1.0), "sky_gradient_bottom": Color(0.5, 0.2, 0.1, 1.0),
		"decorations": ["ember", "smoke_bg", "lava_glow", "ash"],
		"unlock_requirement": 32,  # 32 stars needed
		"levels": [
			{"name": "Volcanic Trail", "difficulty": 5.0, "obstacle_speed": 300.0, "spawn_interval": 1.45, "target_distance": 15000.0, "obstacles": ["steam_vent", "hot_rock", "ash_pile", "crack"], "coin_chance": 0.35, "description": "Dormant... for now"},
			{"name": "Lava Fields", "difficulty": 5.4, "obstacle_speed": 330.0, "spawn_interval": 1.35, "target_distance": 18150.0, "obstacles": ["lava_pool", "fire_geyser", "molten_rock", "smoke_cloud"], "coin_chance": 0.35, "description": "Watch your step!"},
			{"name": "Magma Chamber", "difficulty": 5.8, "obstacle_speed": 365.0, "spawn_interval": 1.25, "target_distance": 21900.0, "obstacles": ["lava_bubble", "falling_stalactite", "fire_wall", "magma_wave"], "coin_chance": 0.3, "description": "Inside the mountain"},
			{"name": "Eruption", "difficulty": 6.2, "obstacle_speed": 400.0, "spawn_interval": 1.15, "target_distance": 26000.0, "obstacles": ["lava_bomb", "pyroclastic_flow", "collapsing_ground", "fire_tornado"], "coin_chance": 0.3, "description": "She's blowing!"},
			{"name": "Caldera Escape", "difficulty": 6.5, "obstacle_speed": 440.0, "spawn_interval": 1.05, "target_distance": 33000.0, "obstacles": ["lava_bomb", "pyroclastic_flow", "meteor", "fire_tornado", "collapsing_ground"], "coin_chance": 0.25, "description": "The final challenge!"}
		]
	}
]

# =============================================================================
# GAME STATE
# =============================================================================

var current_world_index: int = 0
var current_level_index: int = 0
var distance: float = 0.0
var coins: int = 0  # Coins collected this run
var total_coins: int = 0  # Total coins (currency)
var coins_available: int = 0  # Total coins spawned this level
var current_shoe: int = ShoeType.BAREFOOT
var unlocked_shoes: Array[bool] = [true, false, false, false]
var levels_completed: Array = []  # 2D array [world][level] = bool
var level_stars: Array = []  # 2D array [world][level] = int (0-3)
var level_best_coins: Array = []  # 2D array [world][level] = float (percentage)
var _scene_transition_locked: bool = false  # Prevents double scene transitions

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_initialize_progress_arrays()
	load_game()

	# Reset tutorial in TEST_MODE so it shows every time
	if TEST_MODE:
		call_deferred("_reset_tutorial_for_testing")


func _reset_tutorial_for_testing() -> void:
	if TutorialManager:
		TutorialManager.reset_tutorial()
		print("[TEST MODE] Tutorial reset for testing")


func _initialize_progress_arrays() -> void:
	levels_completed.clear()
	level_stars.clear()
	level_best_coins.clear()
	for _w in range(WORLDS_COUNT):
		var completed: Array = []
		var stars: Array = []
		var best_coins: Array = []
		completed.resize(LEVELS_PER_WORLD)
		completed.fill(false)
		stars.resize(LEVELS_PER_WORLD)
		stars.fill(0)
		best_coins.resize(LEVELS_PER_WORLD)
		best_coins.fill(0.0)
		levels_completed.append(completed)
		level_stars.append(stars)
		level_best_coins.append(best_coins)

# =============================================================================
# GETTERS
# =============================================================================

## Returns the data dictionary for the currently selected world.
func get_current_world_data() -> Dictionary:
	return WORLDS[current_world_index]


## Returns the data dictionary for the currently selected level.
func get_current_level_data() -> Dictionary:
	return WORLDS[current_world_index].levels[current_level_index]


## Returns the data dictionary for a specific world by index.
func get_world_data(world_index: int) -> Dictionary:
	return WORLDS[clampi(world_index, 0, WORLDS_COUNT - 1)]


## Returns the data dictionary for a specific level in a specific world.
func get_level_data(world_index: int, level_index: int) -> Dictionary:
	return WORLDS[clampi(world_index, 0, WORLDS_COUNT - 1)].levels[clampi(level_index, 0, LEVELS_PER_WORLD - 1)]


## Returns the data dictionary for the currently equipped shoe.
func get_current_shoe_data() -> Dictionary:
	return SHOES[current_shoe]


## Returns the data dictionary for a specific shoe type.
func get_shoe_data(shoe_type: int) -> Dictionary:
	return SHOES[clampi(shoe_type, 0, SHOES.size() - 1)]


## Returns the total number of stars earned across all worlds.
func get_total_stars() -> int:
	var count: int = 0
	for world in level_stars:
		for stars in world:
			count += stars
	return count


## Returns the total number of levels completed across all worlds.
func get_total_levels_completed() -> int:
	var count: int = 0
	for world in levels_completed:
		for completed in world:
			if completed:
				count += 1
	return count


## Returns whether the specified world is unlocked based on total stars.
func is_world_unlocked(world_index: int) -> bool:
	if TEST_MODE:
		return world_index >= 0 and world_index < WORLDS_COUNT
	if world_index <= 0:
		return true
	if world_index >= WORLDS_COUNT:
		return false
	var required_stars: int = world_index * STARS_PER_WORLD_UNLOCK
	return get_total_stars() >= required_stars


## Returns whether the specified level is unlocked.
func is_level_unlocked(world_index: int, level_index: int) -> bool:
	if TEST_MODE:
		return world_index >= 0 and world_index < WORLDS_COUNT and level_index >= 0 and level_index < LEVELS_PER_WORLD
	if not is_world_unlocked(world_index):
		return false
	if level_index <= 0:
		return true
	if level_index >= LEVELS_PER_WORLD:
		return false
	return levels_completed[world_index][level_index - 1]


## Returns the number of completed levels in the specified world.
func get_world_progress(world_index: int) -> int:
	if world_index < 0 or world_index >= WORLDS_COUNT:
		return 0
	var count: int = 0
	for completed in levels_completed[world_index]:
		if completed:
			count += 1
	return count


## Returns the number of stars earned in the specified world.
func get_world_stars(world_index: int) -> int:
	if world_index < 0 or world_index >= WORLDS_COUNT:
		return 0
	var count: int = 0
	for stars in level_stars[world_index]:
		count += stars
	return count


## Returns the stars for a specific level.
func get_level_stars(world_index: int, level_index: int) -> int:
	if world_index < 0 or world_index >= WORLDS_COUNT:
		return 0
	if level_index < 0 or level_index >= LEVELS_PER_WORLD:
		return 0
	return level_stars[world_index][level_index]


## Calculates stars based on coin collection percentage.
func calculate_stars(coin_percentage: float) -> int:
	if coin_percentage >= STAR_3_THRESHOLD:
		return 3
	elif coin_percentage >= STAR_2_THRESHOLD:
		return 2
	elif coin_percentage >= STAR_1_THRESHOLD:
		return 1
	else:
		return 0

# =============================================================================
# GAME FLOW
# =============================================================================

## Starts the specified level in the specified world.
func start_level(world_index: int, level_index: int) -> void:
	current_world_index = clampi(world_index, 0, WORLDS_COUNT - 1)
	current_level_index = clampi(level_index, 0, LEVELS_PER_WORLD - 1)
	_reset_session()
	_safe_change_scene(SCENE_GAME)


## Restarts the current level.
func restart_level() -> void:
	_reset_session()
	_safe_change_scene(SCENE_GAME)


## Completes the current level and saves progress.
func complete_level() -> void:
	levels_completed[current_world_index][current_level_index] = true
	
	# Calculate and update stars based on coin collection
	var coin_percentage: float = 0.0
	if coins_available > 0:
		coin_percentage = float(coins) / float(coins_available)
	var earned_stars: int = calculate_stars(coin_percentage)
	
	# Only update if better than previous
	if earned_stars > level_stars[current_world_index][current_level_index]:
		level_stars[current_world_index][current_level_index] = earned_stars
	if coin_percentage > level_best_coins[current_world_index][current_level_index]:
		level_best_coins[current_world_index][current_level_index] = coin_percentage
	
	total_coins += coins
	save_game()
	level_completed.emit(current_world_index, current_level_index)
	stars_earned.emit(earned_stars)
	_safe_change_scene(SCENE_LEVEL_COMPLETE)


## Handles game over state, applies coin penalty, and saves.
func game_over() -> void:
	total_coins += int(coins * DEATH_COIN_PENALTY)
	save_game()
	_safe_change_scene(SCENE_GAME_OVER)


func _reset_session() -> void:
	coins = 0
	coins_available = 0
	distance = 0.0

# =============================================================================
# SCORING & DISTANCE
# =============================================================================

## Adds distance traveled.
func add_distance(dist: float) -> void:
	distance += dist
	distance_changed.emit(distance)


## Collects a coin.
func collect_coin(value: int = 1) -> void:
	coins += value
	coins_changed.emit(coins)


## Records that a coin was spawned (for star calculation).
func record_coin_spawned(value: int = 1) -> void:
	coins_available += value


## Returns the current progress as a percentage (0.0 to 1.0).
func get_level_progress() -> float:
	var level_data: Dictionary = get_current_level_data()
	var target: float = level_data.target_distance
	if target <= 0:
		return 0.0
	return clampf(distance / target, 0.0, 1.0)


## Returns whether the level is complete (distance reached).
func is_level_distance_complete() -> bool:
	var level_data: Dictionary = get_current_level_data()
	return distance >= level_data.target_distance

# =============================================================================
# SHOP
# =============================================================================

## Returns whether the player can afford the specified shoe.
func can_afford_shoe(shoe_type: int) -> bool:
	if shoe_type < 0 or shoe_type >= SHOES.size():
		return false
	if TEST_MODE:
		return true
	return total_coins >= SHOES[shoe_type].cost


## Attempts to purchase a shoe. Returns true if successful.
func purchase_shoe(shoe_type: int) -> bool:
	if shoe_type < 0 or shoe_type >= SHOES.size():
		return false
	if unlocked_shoes[shoe_type]:
		return false
	if not can_afford_shoe(shoe_type):
		return false
	total_coins -= SHOES[shoe_type].cost
	unlocked_shoes[shoe_type] = true
	save_game()
	shoe_purchased.emit(shoe_type)
	return true


## Equips the specified shoe if it's unlocked.
func equip_shoe(shoe_type: int) -> void:
	if shoe_type < 0 or shoe_type >= SHOES.size():
		return
	if not TEST_MODE and not unlocked_shoes[shoe_type]:
		return
	current_shoe = shoe_type
	if not TEST_MODE:
		save_game()
	shoe_equipped.emit(shoe_type)

# =============================================================================
# NAVIGATION
# =============================================================================

## Safely changes to a scene with error handling, transition lock, and fallback.
func _safe_change_scene(scene_path: String) -> void:
	# Prevent double transitions (race condition guard)
	if _scene_transition_locked:
		push_warning("[GameManager] Scene transition already in progress, ignoring: %s" % scene_path)
		return
	if not ResourceLoader.exists(scene_path):
		push_error("[GameManager] Scene not found: %s" % scene_path)
		if scene_path != SCENE_MAIN_MENU and ResourceLoader.exists(SCENE_MAIN_MENU):
			push_warning("[GameManager] Falling back to main menu")
			get_tree().change_scene_to_file(SCENE_MAIN_MENU)
		return
	_scene_transition_locked = true
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[GameManager] Failed to change scene to %s (error: %s)" % [scene_path, err])
		_scene_transition_locked = false
	else:
		# Unlock on next frame after scene has changed
		call_deferred("_unlock_scene_transition")


## Unlocks scene transitions after the current transition completes.
func _unlock_scene_transition() -> void:
	_scene_transition_locked = false


## Navigates to the main menu scene.
func go_to_main_menu() -> void:
	_safe_change_scene(SCENE_MAIN_MENU)


## Navigates to the world selection scene.
func go_to_world_select() -> void:
	_safe_change_scene(SCENE_WORLD_SELECT)


## Navigates to the level selection scene for the specified world.
func go_to_level_select(world_index: int) -> void:
	current_world_index = clampi(world_index, 0, WORLDS_COUNT - 1)
	_safe_change_scene(SCENE_LEVEL_SELECT)


## Navigates to the shop scene.
func go_to_shop() -> void:
	_safe_change_scene(SCENE_SHOP)


## Navigates to the settings scene.
func go_to_settings() -> void:
	_safe_change_scene(SCENE_SETTINGS)


## Navigates to the victory scene.
func go_to_victory() -> void:
	_safe_change_scene(SCENE_VICTORY)

# =============================================================================
# SAVE/LOAD
# =============================================================================

## Derives the save encryption key from split components at runtime.
## Keeps the key out of plaintext in the exported binary.
## IMPORTANT: Must produce the same key as previous versions for save compatibility.
static func _derive_save_key() -> String:
	var parts: PackedStringArray = [
		"Side", "Step", "_K4i", "_20", "26_$", "ecure"
	]
	return "".join(parts)


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("meta", "game_version", GAME_VERSION)
	config.set_value("progress", "current_shoe", current_shoe)
	config.set_value("progress", "unlocked_shoes", unlocked_shoes)
	config.set_value("progress", "levels_completed", levels_completed)
	config.set_value("progress", "level_stars", level_stars)
	config.set_value("progress", "level_best_coins", level_best_coins)
	config.set_value("progress", "total_coins", total_coins)
	# Generate checksum from save data for integrity validation
	config.set_value("meta", "checksum", _compute_checksum())
	# Save encrypted version
	var err := config.save_encrypted_pass(SAVE_PATH_ENCRYPTED, SAVE_ENCRYPTION_KEY)
	if err != OK:
		push_error("[GameManager] Failed to save encrypted game: %s" % err)
		# Fallback to unencrypted save
		err = config.save(SAVE_PATH)
		if err != OK:
			push_error("[GameManager] Failed to save game (fallback): %s" % err)

func load_game() -> void:
	var config := ConfigFile.new()
	# Try encrypted save first
	var loaded: bool = false
	if FileAccess.file_exists(SAVE_PATH_ENCRYPTED):
		if config.load_encrypted_pass(SAVE_PATH_ENCRYPTED, SAVE_ENCRYPTION_KEY) == OK:
			loaded = true
	# Fallback to unencrypted save (for migration from older versions)
	if not loaded:
		if config.load(SAVE_PATH) != OK:
			return

	var save_version: int = config.get_value("meta", "save_version", 0)

	# Handle version migrations
	if save_version < SAVE_VERSION:
		_migrate_save(config, save_version)

	current_shoe = config.get_value("progress", "current_shoe", ShoeType.BAREFOOT)
	total_coins = config.get_value("progress", "total_coins", 0)

	# Validate data ranges
	current_shoe = clampi(current_shoe, 0, SHOES.size() - 1)
	total_coins = maxi(total_coins, 0)

	var loaded_shoes: Array = config.get_value("progress", "unlocked_shoes", [])
	if loaded_shoes.size() == SHOES.size():
		unlocked_shoes.clear()
		for val in loaded_shoes:
			unlocked_shoes.append(bool(val))

	var loaded_completed: Array = config.get_value("progress", "levels_completed", [])
	if loaded_completed.size() == WORLDS_COUNT:
		levels_completed = loaded_completed

	var loaded_stars: Array = config.get_value("progress", "level_stars", [])
	if loaded_stars.size() == WORLDS_COUNT:
		level_stars = loaded_stars

	var loaded_best_coins: Array = config.get_value("progress", "level_best_coins", [])
	if loaded_best_coins.size() == WORLDS_COUNT:
		level_best_coins = loaded_best_coins

	# Validate star values are in range (0-3)
	for w in range(WORLDS_COUNT):
		if level_stars.size() > w:
			for l in range(LEVELS_PER_WORLD):
				if level_stars[w].size() > l:
					level_stars[w][l] = clampi(level_stars[w][l], 0, 3)

	# Validate checksum (warn but don't reject - allows pre-checksum saves)
	var stored_checksum: String = config.get_value("meta", "checksum", "")
	if stored_checksum != "" and stored_checksum != _compute_checksum():
		push_warning("[GameManager] Save file checksum mismatch - data may be corrupted or tampered")


## Migrates save data from older versions.
func _migrate_save(config: ConfigFile, from_version: int) -> void:
	print("Migrating save from version %d to %d" % [from_version, SAVE_VERSION])
	
	# Version 0/1 -> 2: Add star system, remove score-based
	if from_version < 2:
		# Initialize stars based on completed levels (give 1 star for each)
		for w in range(WORLDS_COUNT):
			for l in range(LEVELS_PER_WORLD):
				if levels_completed.size() > w and levels_completed[w].size() > l:
					if levels_completed[w][l]:
						level_stars[w][l] = 1  # Give 1 star for previously completed
		print("Migrated: Added star system, granted 1 star per completed level")


## Computes a simple checksum from current save data for integrity validation.
func _compute_checksum() -> String:
	var data: String = "%d|%d|%s|%s|%s|%s" % [
		current_shoe, total_coins,
		str(unlocked_shoes), str(levels_completed),
		str(level_stars), str(level_best_coins)
	]
	return str(data.hash())


func reset_progress() -> void:
	current_shoe = ShoeType.BAREFOOT
	unlocked_shoes = [true, false, false, false]
	total_coins = 0
	_initialize_progress_arrays()
	save_game()
