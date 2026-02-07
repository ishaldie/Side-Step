## Main Game Scene Controller
## Manages gameplay including spawning, scoring, and game flow.
extends Node2D

# =============================================================================
# CONSTANTS
# =============================================================================

const SPAWN_X: float = 550.0
const GROUND_LEVEL_Y: float = 650.0  # Visual ground top (matches player GROUND_Y for feet alignment)
const DUCK_OBSTACLE_Y: float = 570.0  # Consistent height for duck-under obstacles
const FLYING_OBSTACLE_Y_MIN: float = 500.0  # Flying obstacle range
const FLYING_OBSTACLE_Y_MAX: float = 560.0

const COIN_Y_MIN: float = 500.0  # Default min (closer to ground)
const COIN_Y_MAX: float = 600.0  # Default max
const COIN_SPAWN_X: float = 600.0
const COIN_LINE_SPACING: float = 40.0
const COIN_ARC_SPACING: float = 35.0
const COIN_ARC_AMPLITUDE: float = 40.0  # Arc height variation
const COIN_ARC_FREQUENCY: float = 0.6

# Jump physics constants for calculating reachable heights
# Max jump height = jump_force² / (2 * GRAVITY) where GRAVITY = 980
# Single jump: Barefoot=117px (Y=533), Flip-flops=138px (Y=512), Running=160px (Y=490), Winged=184px (Y=466)
# Double jump adds: first_jump_height + (force*0.85)²/(2*980)
# Flip-flops double: 138 + 100 = 238px total (reaches Y=412)
const GROUND_Y: float = 650.0
const GRAVITY: float = 980.0

# World-specific coin heights (Y position, lower = higher on screen)
# World 1: Must be reachable with BAREFOOT SINGLE JUMP (reaches Y=533, use Y=545 with buffer)
# World 2+: Can require DOUBLE JUMP (flip-flops reach Y=412, so can go higher)
const COIN_Y_BY_WORLD: Array[Vector2] = [
	Vector2(545.0, 620.0),  # World 1: Road - barefoot single jump range
	Vector2(480.0, 600.0),  # World 2: Soccer - needs flip-flops double jump for highest
	Vector2(450.0, 580.0),  # World 3: Beach - needs running shoes double jump for highest
	Vector2(420.0, 560.0),  # World 4: Underwater - needs good double jump
	Vector2(400.0, 540.0),  # World 5: Volcano - needs winged shoes for highest coins
]

# Minimum coins to guarantee per level
const MIN_COINS_PER_LEVEL: int = 20

# Flag constants
const FLAG_HEIGHT: float = 80.0
const FLAG_POLE_WIDTH: float = 6.0
const FLAG_CLOTH_WIDTH: float = 50.0
const FLAG_CLOTH_HEIGHT: float = 35.0

const DEATH_DELAY: float = 0.7
const VICTORY_DELAY: float = 0.8
const VICTORY_JUMP_HEIGHT: float = 50.0
const VICTORY_JUMP_UP_DURATION: float = 0.3
const VICTORY_JUMP_DOWN_DURATION: float = 0.2

const DISTANCE_SCALE: float = 1.0  # Score accumulates at obstacle_speed / 10 per second
const PROGRESS_NEAR_COMPLETE: float = 0.8

enum CoinPattern { SINGLE, LINE, ARC }

# =============================================================================
# STATE
# =============================================================================

var _world_data: Dictionary
var _level_data: Dictionary
var _game_active: bool = false
var _game_paused: bool = false
var _flag_spawned: bool = false
var _finish_flag: Node2D = null
var _guaranteed_coins_spawned: int = 0  # Track coins for minimum guarantee

# Cached reference to obstacle configs for flying check
var _obstacle_configs: Dictionary

# Background generator instance
var _bg_generator: BackgroundGenerator

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _player: CharacterBody2D = $Player
@onready var _obstacle_container: Node2D = $ObstacleContainer
@onready var _coin_container: Node2D = $CoinContainer
@onready var _background: ColorRect = $Background
@onready var _ground_rect: ColorRect = $Ground/GroundRect
@onready var _obstacle_timer: Timer = $ObstacleTimer

@onready var _score_label: Label = $UI/ScoreLabel
@onready var _coin_label: Label = $UI/CoinLabel
@onready var _level_label: Label = $UI/LevelLabel
@onready var _world_label: Label = $UI/WorldLabel
@onready var _progress_bar: ProgressBar = $UI/ProgressBar
@onready var _difficulty_label: Label = $UI/DifficultyLabel
@onready var _game_over_panel: Panel = $UI/GameOverPanel
@onready var _pause_panel: Panel = $UI/PausePanel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_world_data = GameManager.get_current_world_data()
	_level_data = GameManager.get_current_level_data()
	_obstacle_configs = preload("res://scripts/obstacle.gd").CONFIGS
	
	_setup_visuals()
	_player.died.connect(_on_player_died)
	
	_update_ui()
	_game_over_panel.hide()
	_pause_panel.hide()
	
	_start_game()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _process(delta: float) -> void:
	if not _game_active or _game_paused:
		return
	
	GameManager.add_distance(_level_data.obstacle_speed * delta * DISTANCE_SCALE)
	_update_ui()
	
	# Spawn flag when we reach target distance
	if not _flag_spawned and GameManager.is_level_distance_complete():
		_spawn_finish_flag()
	
	# Move flag toward player (like obstacles)
	if _finish_flag and is_instance_valid(_finish_flag):
		_finish_flag.position.x -= _level_data.obstacle_speed * delta
		
		# Level complete when player passes the flag
		if _finish_flag.position.x <= _player.position.x:
			_complete_level()

# =============================================================================
# SETUP
# =============================================================================

func _setup_visuals() -> void:
	# Initialize background generator
	_bg_generator = BackgroundGenerator.new(self)

	# Hide the old solid color backgrounds (replaced by background images)
	_background.visible = false
	_ground_rect.visible = false
	_world_label.text = "%s %s" % [_world_data.icon, _world_data.name]
	_level_label.text = _level_data.name
	_difficulty_label.text = "⚡ %s" % _level_data.difficulty

	# Create themed background using the generator
	_bg_generator.create_background(GameManager.current_world_index, _world_data)
	# Ground is now part of the background image - no separate tiles needed


func _start_game() -> void:
	_game_active = true
	_flag_spawned = false
	_finish_flag = null
	_guaranteed_coins_spawned = 0
	_obstacle_timer.wait_time = _level_data.spawn_interval
	_obstacle_timer.start()
	
	# Start background music
	AudioManager.start_game_music()
	
	# Log analytics event
	if Analytics:
		Analytics.log_level_start(GameManager.current_world_index, GameManager.current_level_index)

# =============================================================================
# PAUSE
# =============================================================================

var _quit_confirmation_shown: bool = false

func _toggle_pause() -> void:
	if not _game_active:
		return
	_game_paused = not _game_paused
	get_tree().paused = _game_paused
	_pause_panel.visible = _game_paused
	_quit_confirmation_shown = false
	
	if _game_paused:
		AudioManager.pause_music()
		$UI/PausePanel/VBoxContainer/QuitButton.text = "QUIT"
		_update_settings_buttons()
	else:
		AudioManager.resume_music()

# =============================================================================
# SPAWNING
# =============================================================================

func _spawn_obstacle() -> void:
	if not _game_active:
		return
	
	var obstacle: Area2D = ObjectPool.get_obstacle()
	if not obstacle:
		push_warning("[Game] Failed to get obstacle from pool")
		return
	
	var obstacles: Array = _level_data.obstacles
	var obs_type: String = obstacles[randi() % obstacles.size()]
	
	# Get obstacle config for height and type
	var config: Dictionary = _obstacle_configs.get(obs_type, {})
	var obs_height: float = config.get("height", 40.0)
	var is_flying: bool = config.get("flying", false)
	var is_duck_under: bool = config.get("duck_under", false)
	var height_offset: float = config.get("height_offset", 0.0)
	
	# Calculate Y position based on obstacle type
	var y_pos: float
	if is_flying:
		# Flying obstacles at head height range
		y_pos = randf_range(FLYING_OBSTACLE_Y_MIN, FLYING_OBSTACLE_Y_MAX)
	elif is_duck_under and height_offset != 0.0:
		# Duck-under obstacles that use height_offset (barrier, beam)
		# Position at ground but the sprite/collision will be raised by height_offset
		y_pos = GROUND_LEVEL_Y - (obs_height / 2.0)
	else:
		# Ground obstacles - bottom of obstacle at ground level
		y_pos = GROUND_LEVEL_Y - (obs_height / 2.0)
	
	obstacle.reset()
	obstacle.position = Vector2(SPAWN_X, y_pos)
	obstacle.setup(obs_type, _level_data.obstacle_speed, y_pos)
	
	# Connect projectile spawning signal if obstacle can shoot
	if obstacle.has_signal("spawn_projectile"):
		if not obstacle.spawn_projectile.is_connected(_on_spawn_projectile):
			obstacle.spawn_projectile.connect(_on_spawn_projectile)
	
	_obstacle_container.add_child(obstacle)
	
	# Determine if we should spawn coins
	# Either by random chance OR if we haven't hit minimum coins and we're past 20% of level
	var progress: float = GameManager.get_level_progress()
	var need_guaranteed_coins: bool = _guaranteed_coins_spawned < MIN_COINS_PER_LEVEL and progress > 0.2
	var random_spawn: bool = randf() < _level_data.coin_chance
	
	# If we're behind on coins, increase spawn rate
	if need_guaranteed_coins:
		# Calculate how many coins we should have by now
		var expected_coins: int = int(progress * MIN_COINS_PER_LEVEL)
		if _guaranteed_coins_spawned < expected_coins:
			random_spawn = true  # Force spawn to catch up
	
	if random_spawn:
		_spawn_coin_pattern()


## Spawns a projectile (like bananas from backpacks)
func _spawn_projectile(projectile_type: String, pos: Vector2, vel: Vector2) -> void:
	if not _game_active:
		return
	
	var projectile: Area2D = ObjectPool.get_obstacle()
	if not projectile:
		return
	
	projectile.reset()
	projectile.position = pos
	projectile.setup_projectile(projectile_type, _level_data.obstacle_speed, pos.y, vel)
	_obstacle_container.add_child(projectile)


## Handler for projectile spawning signal
func _on_spawn_projectile(projectile_type: String, pos: Vector2, vel: Vector2) -> void:
	_spawn_projectile(projectile_type, pos, vel)


## Checks obstacle config to determine if it's a flying type.
func _is_flying_obstacle(obs_type: String) -> bool:
	if _obstacle_configs.has(obs_type):
		return _obstacle_configs[obs_type].get("flying", false)
	return false


func _spawn_coin_pattern() -> void:
	var pattern: int = randi() % CoinPattern.size()
	
	# Get world-specific coin height range
	var world_idx: int = clampi(GameManager.current_world_index, 0, COIN_Y_BY_WORLD.size() - 1)
	var coin_y_range: Vector2 = COIN_Y_BY_WORLD[world_idx]
	var base_y: float = randf_range(coin_y_range.x, coin_y_range.y)
	
	# World 1 special handling: clamp to barefoot-reachable heights
	# Barefoot single jump reaches Y=533, so minimum Y should be ~545 with buffer
	if world_idx == 0:
		base_y = maxf(base_y, 545.0)
	
	match pattern:
		CoinPattern.SINGLE:
			_spawn_coin(COIN_SPAWN_X, base_y)
		CoinPattern.LINE:
			for i in range(3):
				_spawn_coin(COIN_SPAWN_X + i * COIN_LINE_SPACING, base_y)
		CoinPattern.ARC:
			for i in range(5):
				var arc_y: float = base_y - sin(i * COIN_ARC_FREQUENCY) * COIN_ARC_AMPLITUDE
				# World 1: clamp arc coins to barefoot range
				if world_idx == 0:
					arc_y = maxf(arc_y, 545.0)
				_spawn_coin(COIN_SPAWN_X + i * COIN_ARC_SPACING, arc_y)


func _spawn_coin(x: float, y: float) -> void:
	var coin: Area2D = ObjectPool.get_coin()
	if not coin:
		push_warning("[Game] Failed to get coin from pool")
		return
	coin.position = Vector2(x, y)
	coin.setup(_level_data.obstacle_speed, y, 1)
	coin.reset()
	_coin_container.add_child(coin)
	
	# Track for minimum guarantee
	_guaranteed_coins_spawned += 1
	
	# Record that a coin was spawned (for star calculation)
	GameManager.record_coin_spawned(1)


## Spawns the finish flag on the right side - level ends when player passes it
func _spawn_finish_flag() -> void:
	if _flag_spawned:
		return
	_flag_spawned = true
	_obstacle_timer.stop()  # Stop spawning obstacles

	_finish_flag = Node2D.new()
	_finish_flag.name = "FinishFlag"
	_finish_flag.position = Vector2(SPAWN_X, GROUND_Y)

	# Load world-themed flag
	var flag_sprite := Sprite2D.new()
	flag_sprite.texture = _get_world_flag_texture()
	if flag_sprite.texture:
		var tex_size: Vector2 = flag_sprite.texture.get_size()
		var desired_height: float = FLAG_HEIGHT + FLAG_CLOTH_HEIGHT
		var scale_factor: float = desired_height / tex_size.y
		flag_sprite.scale = Vector2(scale_factor, scale_factor)
		flag_sprite.position = Vector2(0, -desired_height / 2.0)
	_finish_flag.add_child(flag_sprite)

	add_child(_finish_flag)


## Returns the flag texture for the current world
func _get_world_flag_texture() -> Texture2D:
	const WORLD_FLAGS: Array[String] = [
		"res://assets/flags/flag_road.png",
		"res://assets/flags/flag_soccer.png",
		"res://assets/flags/flag_beach.png",
		"res://assets/flags/flag_underwater.png",
		"res://assets/flags/flag_volcano.png"
	]
	var world_index: int = clampi(GameManager.current_world_index, 0, WORLD_FLAGS.size() - 1)
	var path: String = WORLD_FLAGS[world_index]
	if not ResourceLoader.exists(path):
		push_warning("[Game] Flag texture not found: %s" % path)
		return null
	var tex: Texture2D = load(path)
	if not tex:
		push_warning("[Game] Failed to load flag texture: %s" % path)
	return tex


# =============================================================================
# GAME FLOW
# =============================================================================

func _on_obstacle_timer_timeout() -> void:
	if _game_active and not _game_paused:
		_spawn_obstacle()


func _on_player_died() -> void:
	_game_active = false
	_obstacle_timer.stop()
	
	# Log analytics
	if Analytics:
		Analytics.log_level_fail(
			GameManager.current_world_index,
			GameManager.current_level_index,
			GameManager.distance,
			GameManager.coins
		)
	
	await get_tree().create_timer(DEATH_DELAY).timeout
	ObjectPool.release_all()
	GameManager.game_over()


func _complete_level() -> void:
	_game_active = false
	_obstacle_timer.stop()
	AudioManager.stop_music()
	AudioManager.play_level_complete()
	
	var original_y: float = _player.position.y
	var tween := create_tween()
	tween.tween_property(_player, "position:y", original_y - VICTORY_JUMP_HEIGHT, VICTORY_JUMP_UP_DURATION)
	tween.tween_property(_player, "position:y", original_y, VICTORY_JUMP_DOWN_DURATION)
	
	await get_tree().create_timer(VICTORY_DELAY).timeout
	ObjectPool.release_all()
	GameManager.complete_level()

# =============================================================================
# UI
# =============================================================================

func _update_ui() -> void:
	# Show distance in meters (divide by 100 for display)
	var distance_meters: int = int(GameManager.distance / 100.0)
	_score_label.text = "%dm" % distance_meters
	_coin_label.text = " %d" % GameManager.coins

	# Add HUD coin icon if not already present
	UIUtils.add_coin_icon(_coin_label, Vector2(16, 16), Vector2(-18, 2))

	var progress: float = GameManager.get_level_progress()
	_progress_bar.value = progress * 100.0

	if progress >= 1.0:
		_score_label.modulate = Color.GREEN
	elif progress >= PROGRESS_NEAR_COMPLETE:
		_score_label.modulate = Color.YELLOW
	else:
		_score_label.modulate = Color.WHITE

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_pause_button_pressed() -> void:
	AudioManager.play_button()
	_toggle_pause()
	_update_settings_buttons()


func _on_retry_button_pressed() -> void:
	AudioManager.play_button()
	get_tree().paused = false
	ObjectPool.release_all()
	GameManager.restart_level()


func _on_resume_button_pressed() -> void:
	AudioManager.play_button()
	_quit_confirmation_shown = false
	_toggle_pause()


func _on_quit_button_pressed() -> void:
	AudioManager.play_button()
	if not _quit_confirmation_shown:
		_quit_confirmation_shown = true
		$UI/PausePanel/VBoxContainer/QuitButton.text = "CONFIRM QUIT?"
		return
	
	get_tree().paused = false
	ObjectPool.release_all()
	AudioManager.stop_music()
	GameManager.go_to_level_select(GameManager.current_world_index)


func _on_menu_button_pressed() -> void:
	AudioManager.play_button()
	get_tree().paused = false
	ObjectPool.release_all()
	AudioManager.stop_music()
	GameManager.go_to_level_select(GameManager.current_world_index)


func _on_music_toggle_pressed() -> void:
	var enabled: bool = AudioManager.is_music_enabled()
	AudioManager.set_music_enabled(not enabled)
	_update_settings_buttons()
	AudioManager.play_button()


func _on_sfx_toggle_pressed() -> void:
	var enabled: bool = AudioManager.is_sfx_enabled()
	AudioManager.set_sfx_enabled(not enabled)
	_update_settings_buttons()


func _on_shop_button_pressed() -> void:
	AudioManager.play_button()
	get_tree().paused = false
	ObjectPool.release_all()
	GameManager.go_to_shop()


func _update_settings_buttons() -> void:
	var music_btn: Button = $UI/PausePanel/VBoxContainer/MusicToggle
	var sfx_btn: Button = $UI/PausePanel/VBoxContainer/SFXToggle
	
	if AudioManager.is_music_enabled():
		music_btn.text = "Music: ON"
		music_btn.button_pressed = false
	else:
		music_btn.text = "Music: OFF"
		music_btn.button_pressed = true

	if AudioManager.is_sfx_enabled():
		sfx_btn.text = "Sounds: ON"
		sfx_btn.button_pressed = false
	else:
		sfx_btn.text = "Sounds: OFF"
		sfx_btn.button_pressed = true
