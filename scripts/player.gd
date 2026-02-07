## Player Controller
## Handles player movement, jumping, and collision with obstacles.
## Uses a state machine for clear state management.
## Character is a runner kid who upgrades footwear via GameManager.
extends CharacterBody2D

# =============================================================================
# SIGNALS
# =============================================================================

signal died
signal state_changed(old_state: int, new_state: int)

# =============================================================================
# STATE MACHINE
# =============================================================================

enum State {
	IDLE,       # Standing still on ground
	RUNNING,    # Moving on ground
	JUMPING,    # In air from jump (can double jump)
	FALLING,    # In air without jump (from walking off edge)
	DUCKING,    # Crouched on ground
	DASHING,    # Speed boost active
	DEAD        # Game over
}

var _state: State = State.IDLE

# =============================================================================
# CONSTANTS
# =============================================================================

const GRAVITY: float = 980.0
const GROUND_Y: float = 650.0
const SCREEN_LEFT_BOUND: float = 40.0
const SCREEN_RIGHT_BOUND: float = 440.0
const START_X: float = 120.0

const DASH_MULTIPLIER: float = 2.5
const DOUBLE_JUMP_MULTIPLIER: float = 0.85
const MOVEMENT_LERP: float = 0.2
const SQUASH_LERP: float = 0.2
const STRETCH_RECOVERY_LERP: float = 0.1

const INVINCIBILITY_FLASH_SPEED: float = 10.0
const RUN_ANIMATION_INTERVAL: float = 0.1
const RUN_BOB_THRESHOLD: float = 10.0
const RUN_BOB_OFFSET: float = -3.0

const DEATH_ROTATION: float = TAU  # Full rotation
const DEATH_FALL_DISTANCE: float = 100.0
const DEATH_DURATION: float = 0.5

const JUMP_SQUASH: Vector2 = Vector2(0.8, 1.3)
const DOUBLE_JUMP_SQUASH: Vector2 = Vector2(0.7, 1.4)
const DUCK_SQUASH: Vector2 = Vector2(1.4, 0.5)  # Wide and short when ducking

# Input buffering
const INPUT_BUFFER_TIME: float = 0.2  # 200ms buffer window (generous for mobile)
const COYOTE_TIME: float = 0.15  # 150ms grace period after leaving ground

# Ducking
const DUCK_HEIGHT_SCALE: float = 0.5  # Player is 50% of normal height when ducking
const DUCK_COLLISION_OFFSET: float = 12.0  # Move collision down when ducking
const NORMAL_COLLISION_HEIGHT: float = 50.0  # Match Kai sprite size (70x94 at 0.8 scale)

# Touch input zones and gestures - OPTIMIZED FOR iOS
const TOUCH_DUCK_ZONE_TOP: float = 0.65  # Bottom 35% of screen = duck zone (expanded for easier ducking)
const SWIPE_MIN_DISTANCE: float = 30.0  # Lower threshold for easier swipes
const SWIPE_MAX_TIME: float = 0.4  # Longer swipe window
const DOUBLE_TAP_TIME: float = 0.3  # Time window for double-tap to double jump
const SWIPE_DOWN_DUCK: bool = true  # Enable swipe-down gesture for ducking

# Dash
const DASH_DURATION: float = 0.25  # How long dash lasts
const DASH_COOLDOWN_TIME: float = 1.0  # Cooldown between dashes

# Fast fall - pressing down while airborne accelerates descent
const FAST_FALL_MULTIPLIER: float = 3.5  # How much faster gravity is applied when fast falling

# =============================================================================
# SHOE STATS (loaded at runtime)
# =============================================================================

var move_speed: float = 220.0
var jump_force: float = 480.0
var can_double_jump: bool = false
var can_dash: bool = false

# =============================================================================
# STATE (legacy compatibility - derived from _state)
# =============================================================================

## Returns true if player is dead.
var is_dead: bool:
	get: return _state == State.DEAD

## Returns true if player is on ground.
var is_on_ground: bool:
	get: return _state in [State.IDLE, State.RUNNING, State.DUCKING]

## Returns true if player is ducking.
var is_ducking: bool:
	get: return _state == State.DUCKING

## Returns true if player is dashing.
var is_dashing: bool:
	get: return _state == State.DASHING

## Returns true if player is in the air (jumping or falling).
var is_in_air: bool:
	get: return _state in [State.JUMPING, State.FALLING]

var has_double_jumped: bool = false
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var invincible: bool = false
var invincible_timer: float = 0.0

# =============================================================================
# ANIMATION
# =============================================================================

var _run_frame: int = 0
var _run_timer: float = 0.0
var _squash_stretch: Vector2 = Vector2.ONE

# =============================================================================
# INPUT BUFFERING
# =============================================================================

var _jump_buffer_timer: float = 0.0
var _coyote_timer: float = 0.0
var _screen_height: float = 800.0  # Default, updated in _ready

# =============================================================================
# TOUCH GESTURE STATE
# =============================================================================

var _touch_start_pos: Dictionary = {}  # touch_index -> start position
var _touch_start_time: Dictionary = {}  # touch_index -> start time
var _touch_is_duck: Dictionary = {}  # touch_index -> bool (is this touch in duck zone)
var _last_tap_time: float = 0.0  # For double-tap detection
var _haptic_enabled: bool = true  # iOS haptic feedback

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _sprite: Sprite2D = $Sprite
@onready var _collision: CollisionShape2D = $CollisionShape2D

# =============================================================================
# KAI SPRITE TEXTURES
# =============================================================================

# Map shoe type to Kai sprite folder name
const SHOE_TO_TIER: Dictionary = {
	0: "barefoot",       # BAREFOOT
	1: "flipflops",      # FLIP_FLOPS
	2: "runningshoes",   # RUNNING_SHOES
	3: "winged"          # WINGED_SHOES
}

# Preloaded texture sets per tier (avoids runtime load() calls)
const PRELOADED_TEXTURES: Dictionary = {
	"barefoot": {
		"stand": preload("res://assets/kai_sprites/barefoot/character_stand.png"),
		"walk1": preload("res://assets/kai_sprites/barefoot/character_walk1.png"),
		"walk2": preload("res://assets/kai_sprites/barefoot/character_walk2.png"),
		"jump": preload("res://assets/kai_sprites/barefoot/character_jump.png"),
		"duck": preload("res://assets/kai_sprites/barefoot/character_duck.png"),
	},
	"flipflops": {
		"stand": preload("res://assets/kai_sprites/flipflops/character_stand.png"),
		"walk1": preload("res://assets/kai_sprites/flipflops/character_walk1.png"),
		"walk2": preload("res://assets/kai_sprites/flipflops/character_walk2.png"),
		"jump": preload("res://assets/kai_sprites/flipflops/character_jump.png"),
		"duck": preload("res://assets/kai_sprites/flipflops/character_duck.png"),
	},
	"runningshoes": {
		"stand": preload("res://assets/kai_sprites/runningshoes/character_stand.png"),
		"walk1": preload("res://assets/kai_sprites/runningshoes/character_walk1.png"),
		"walk2": preload("res://assets/kai_sprites/runningshoes/character_walk2.png"),
		"jump": preload("res://assets/kai_sprites/runningshoes/character_jump.png"),
		"duck": preload("res://assets/kai_sprites/runningshoes/character_duck.png"),
	},
	"winged": {
		"stand": preload("res://assets/kai_sprites/winged/character_stand.png"),
		"walk1": preload("res://assets/kai_sprites/winged/character_walk1.png"),
		"walk2": preload("res://assets/kai_sprites/winged/character_walk2.png"),
		"jump": preload("res://assets/kai_sprites/winged/character_jump.png"),
		"duck": preload("res://assets/kai_sprites/winged/character_duck.png"),
	},
}

# Active texture set (reference to preloaded textures)
var _textures: Dictionary = {}

# Player sprite scale (70x94 Kai sprites)
# Scale up slightly for better visibility
const PLAYER_SPRITE_SCALE: Vector2 = Vector2(0.8, 0.8)

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	add_to_group("player")
	_apply_shoe_stats()
	_load_textures()
	_apply_shoe_visuals()
	position = Vector2(START_X, GROUND_Y)
	_screen_height = get_viewport_rect().size.y
	_change_state(State.IDLE)


## Loads stats from the currently equipped shoe.
func _apply_shoe_stats() -> void:
	var shoe_data: Dictionary = GameManager.get_current_shoe_data()
	move_speed = shoe_data.speed
	jump_force = shoe_data.jump_force
	can_double_jump = shoe_data.double_jump
	can_dash = shoe_data.dash


## Loads Kai character textures for the current shoe type (uses preloaded textures).
func _load_textures() -> void:
	var shoe_type: int = GameManager.current_shoe
	var tier_name: String = SHOE_TO_TIER.get(shoe_type, "barefoot")

	# Use preloaded textures (no runtime load() calls)
	var tier_textures: Dictionary = PRELOADED_TEXTURES.get(tier_name, PRELOADED_TEXTURES["barefoot"])
	_textures = {
		"stand": tier_textures["stand"],
		"walk1": tier_textures["walk1"],
		"walk2": tier_textures["walk2"],
		"jump": tier_textures["jump"],
		"duck": tier_textures["duck"],
		"hit": tier_textures["stand"],  # Use stand as fallback for hit
	}


## Updates character visuals based on current footwear tier.
func _apply_shoe_visuals() -> void:
	_load_textures()
	_sprite.texture = _textures.get("stand")
	_sprite.scale = PLAYER_SPRITE_SCALE
	# Offset sprite so feet align with ground
	# Kai sprites are 70x94, scaled at 0.8 = 56x75 rendered
	# Sprites are bottom-aligned (feet at bottom of image)
	# Sprite center is at player position, offset to put feet at ground level
	# Half sprite height = 75/2 = 37.5, so offset by -37 to align feet with ground
	_sprite.position.y = -37


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	
	_update_invincibility(delta)
	_update_timers(delta)
	_update_state(delta)
	_apply_gravity(delta)
	_check_ground()
	_update_input_buffers(delta)
	_handle_movement(delta)
	move_and_slide()
	_update_animation(delta)
	_update_squash_stretch()


func _input(event: InputEvent) -> void:
	if _state == State.DEAD:
		return
	
	# Keyboard input
	if event.is_action_pressed("jump"):
		_buffer_jump()
	
	if event.is_action_pressed("dash") and can_dash:
		_try_dash()
	
	# Touch input - handle gestures
	if event is InputEventScreenTouch:
		_handle_touch(event)
	
	# Touch drag - for detecting swipes and hold position
	if event is InputEventScreenDrag:
		_handle_touch_drag(event)


## Handles touch start and end events.
func _handle_touch(event: InputEventScreenTouch) -> void:
	# Guard against zero screen height (avoids division by zero)
	if _screen_height <= 0.0:
		_screen_height = 800.0
	# Clamp touch position to valid screen bounds
	var clamped_pos := Vector2(
		clampf(event.position.x, 0.0, get_viewport_rect().size.x),
		clampf(event.position.y, 0.0, _screen_height)
	)
	var normalized_y: float = clamped_pos.y / _screen_height
	var idx: int = event.index

	if event.pressed:
		# Touch started - store info for this touch
		_touch_start_pos[idx] = event.position
		_touch_start_time[idx] = Time.get_ticks_msec() / 1000.0
		
		# IMMEDIATE RESPONSE on touch down
		if normalized_y >= TOUCH_DUCK_ZONE_TOP:
			# Touch in duck zone - start ducking
			_touch_is_duck[idx] = true
			_trigger_haptic_light()
		else:
			# Touch in jump zone - JUMP IMMEDIATELY
			_touch_is_duck[idx] = false
			
			# Check for double-tap (for double jump)
			var current_time: float = Time.get_ticks_msec() / 1000.0
			var is_double_tap: bool = (current_time - _last_tap_time) < DOUBLE_TAP_TIME
			_last_tap_time = current_time
			
			# Buffer the jump
			_buffer_jump()
			_trigger_haptic_medium()
			
			# If double-tap and we're in the air, try double jump immediately
			if is_double_tap and can_double_jump and not has_double_jumped:
				if _state in [State.JUMPING, State.FALLING]:
					_double_jump()
					_trigger_haptic_heavy()
	else:
		# Touch ended
		if _touch_start_pos.has(idx):
			var touch_end_pos: Vector2 = clamped_pos
			var touch_duration: float = (Time.get_ticks_msec() / 1000.0) - _touch_start_time.get(idx, 0.0)
			var swipe_vector: Vector2 = touch_end_pos - _touch_start_pos[idx]
			var swipe_distance: float = swipe_vector.length()
			
			# Check for swipe gestures (dash, etc.)
			if swipe_distance >= SWIPE_MIN_DISTANCE and touch_duration <= SWIPE_MAX_TIME:
				var swipe_angle: float = swipe_vector.angle()
				
				# Swipe right (angle around 0, between -45° and 45°) = dash
				if swipe_angle > -PI * 0.25 and swipe_angle < PI * 0.25:
					if can_dash:
						_try_dash()
						_trigger_haptic_heavy()
				# Swipe up = additional jump (for double jump if available)
				elif swipe_angle < -PI * 0.25 and swipe_angle > -PI * 0.75:
					_buffer_jump()
				# Swipe down (angle around PI/2, between 45° and 135°) = start duck
				elif SWIPE_DOWN_DUCK and swipe_angle > PI * 0.25 and swipe_angle < PI * 0.75:
					# Force duck state via setting touch_is_duck
					_touch_is_duck[idx] = true
					_trigger_haptic_light()
			
			# Clean up this touch's data
			_touch_start_pos.erase(idx)
			_touch_start_time.erase(idx)
			_touch_is_duck.erase(idx)


## Triggers light haptic feedback (iOS/Android)
func _trigger_haptic_light() -> void:
	if not _haptic_enabled:
		return
	if OS.get_name() in ["iOS", "Android"]:
		Input.vibrate_handheld(15)  # Very short vibration


## Triggers medium haptic feedback (iOS/Android)
func _trigger_haptic_medium() -> void:
	if not _haptic_enabled:
		return
	if OS.get_name() in ["iOS", "Android"]:
		Input.vibrate_handheld(25)  # Short vibration


## Triggers heavy haptic feedback (iOS/Android)
func _trigger_haptic_heavy() -> void:
	if not _haptic_enabled:
		return
	if OS.get_name() in ["iOS", "Android"]:
		Input.vibrate_handheld(40)  # Medium vibration


## Enables or disables haptic feedback
func set_haptic_enabled(enabled: bool) -> void:
	_haptic_enabled = enabled


## Returns whether haptic feedback is enabled
func is_haptic_enabled() -> bool:
	return _haptic_enabled


## Handles touch drag for continuous gestures.
func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	var idx: int = event.index
	if not _touch_start_pos.has(idx):
		return

	# Guard against zero screen height
	if _screen_height <= 0.0:
		_screen_height = 800.0
	# Update duck state based on current position
	var normalized_y: float = clampf(event.position.y, 0.0, _screen_height) / _screen_height
	_touch_is_duck[idx] = normalized_y >= TOUCH_DUCK_ZONE_TOP


## Returns true if duck input is active (keyboard or any touch in duck zone).
func _is_duck_input_active() -> bool:
	if Input.is_action_pressed("duck"):
		return true
	# Check if ANY touch is currently in the duck zone
	for idx in _touch_is_duck:
		if _touch_is_duck[idx]:
			return true
	return false


## Attempts to start a dash if conditions are met.
func _try_dash() -> void:
	if not can_dash:
		return
	if dash_cooldown > 0:
		return
	if _state == State.DASHING:
		return
	
	dash_timer = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN_TIME
	_change_state(State.DASHING)
	AudioManager.play_jump()  # Use jump sound for now
	# Notify tutorial
	if TutorialManager:
		TutorialManager.on_player_dashed()


## Buffers a jump input for later execution.
func _buffer_jump() -> void:
	_jump_buffer_timer = INPUT_BUFFER_TIME


# =============================================================================
# STATE MACHINE
# =============================================================================

## Changes to a new state, calling exit/enter callbacks.
func _change_state(new_state: State) -> void:
	if new_state == _state:
		return
	
	var old_state := _state
	_on_state_exit(old_state)
	_state = new_state
	_on_state_enter(new_state)
	state_changed.emit(old_state, new_state)


## Called when exiting a state.
func _on_state_exit(state: State) -> void:
	match state:
		State.DUCKING:
			_apply_duck_collision(false)
		State.DASHING:
			pass


## Called when entering a state.
func _on_state_enter(state: State) -> void:
	match state:
		State.JUMPING:
			_squash_stretch = JUMP_SQUASH
			AudioManager.play_jump()
		State.DUCKING:
			_apply_duck_collision(true)
			AudioManager.play_duck()
		State.DEAD:
			AudioManager.play_death()
			ScreenEffects.shake_large()


## Updates the current state based on conditions.
func _update_state(_delta: float) -> void:
	match _state:
		State.IDLE, State.RUNNING:
			_update_ground_state()
		State.JUMPING, State.FALLING:
			_update_air_state()
		State.DUCKING:
			_update_duck_state()
		State.DASHING:
			_update_dash_state()


func _update_ground_state() -> void:
	var wants_duck: bool = _is_duck_input_active()
	var input_dir: float = Input.get_axis("move_left", "move_right")
	
	if wants_duck and velocity.y >= 0:
		_change_state(State.DUCKING)
		# Notify tutorial
		if TutorialManager:
			TutorialManager.on_player_ducked()
	elif absf(input_dir) > 0.1:
		if _state != State.RUNNING:
			_change_state(State.RUNNING)
	else:
		if _state != State.IDLE:
			_change_state(State.IDLE)


func _update_air_state() -> void:
	# Will transition to ground state in _check_ground()
	pass


func _update_duck_state() -> void:
	var wants_duck: bool = _is_duck_input_active()
	if not wants_duck:
		_change_state(State.IDLE)


func _update_dash_state() -> void:
	if dash_timer <= 0:
		if position.y >= GROUND_Y:
			_change_state(State.RUNNING)
		else:
			_change_state(State.FALLING)


## Updates dash and cooldown timers.
func _update_timers(delta: float) -> void:
	if dash_timer > 0:
		dash_timer -= delta
	if dash_cooldown > 0:
		dash_cooldown -= delta

# =============================================================================
# PHYSICS HELPERS
# =============================================================================

func _update_invincibility(delta: float) -> void:
	if not invincible:
		return
	
	invincible_timer -= delta
	# Flash effect
	var flash: bool = fmod(invincible_timer * INVINCIBILITY_FLASH_SPEED, 1.0) > 0.5
	modulate.a = 0.5 if flash else 1.0
	
	if invincible_timer <= 0.0:
		invincible = false
		modulate.a = 1.0


func _apply_duck_collision(ducking: bool) -> void:
	if not _collision or not _collision.shape:
		return
	
	var shape: RectangleShape2D = _collision.shape as RectangleShape2D
	if not shape:
		return
	
	if ducking:
		# Make collision shorter and move it down
		shape.size.y = NORMAL_COLLISION_HEIGHT * DUCK_HEIGHT_SCALE
		_collision.position.y = DUCK_COLLISION_OFFSET
	else:
		# Restore normal collision
		shape.size.y = NORMAL_COLLISION_HEIGHT
		_collision.position.y = 0.0


func _apply_gravity(delta: float) -> void:
	if not is_on_ground and _state != State.DASHING:
		var gravity_multiplier := FAST_FALL_MULTIPLIER if _is_duck_input_active() else 1.0
		velocity.y += GRAVITY * gravity_multiplier * delta


func _check_ground() -> void:
	# Cache air state before potential state change
	var was_in_air := is_in_air

	if position.y >= GROUND_Y:
		position.y = GROUND_Y
		velocity.y = 0.0
		has_double_jumped = false
		_coyote_timer = COYOTE_TIME

		# Transition to ground state if we were in air
		if was_in_air:
			_trigger_haptic_light()  # Landing feedback
			var input_dir: float = Input.get_axis("move_left", "move_right")
			if absf(input_dir) > 0.1:
				_change_state(State.RUNNING)
			else:
				_change_state(State.IDLE)
	else:
		# In air - if we walked off edge, start falling
		if _state in [State.IDLE, State.RUNNING] and _coyote_timer <= 0:
			_change_state(State.FALLING)


## Updates input buffer timers and processes buffered inputs.
func _update_input_buffers(delta: float) -> void:
	# Update coyote time (grace period after leaving ground)
	if not is_on_ground:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	
	# Update jump buffer
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta
		
		# Try to consume the buffered jump
		if _try_jump():
			_jump_buffer_timer = 0.0


func _handle_movement(_delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	var target_speed: float = input_dir * move_speed
	
	if _state == State.DASHING:
		target_speed *= DASH_MULTIPLIER
	
	velocity.x = lerp(velocity.x, target_speed, MOVEMENT_LERP)
	position.x = clampf(position.x, SCREEN_LEFT_BOUND, SCREEN_RIGHT_BOUND)

# =============================================================================
# JUMPING
# =============================================================================

## Attempts to jump, returns true if successful.
func _try_jump() -> bool:
	# Use cached properties instead of array membership tests
	# Can jump if on ground OR within coyote time
	if is_on_ground or _coyote_timer > 0.0:
		_jump()
		return true
	elif can_double_jump and not has_double_jumped and is_in_air:
		_double_jump()
		return true
	return false


func _jump() -> void:
	velocity.y = -jump_force
	_coyote_timer = 0.0  # Consume coyote time
	_change_state(State.JUMPING)
	# Notify tutorial
	if TutorialManager:
		TutorialManager.on_player_jumped()


func _double_jump() -> void:
	velocity.y = -jump_force * DOUBLE_JUMP_MULTIPLIER
	has_double_jumped = true
	_squash_stretch = DOUBLE_JUMP_SQUASH
	AudioManager.play_double_jump()
	# Notify tutorial
	if TutorialManager:
		TutorialManager.on_player_double_jumped()

# =============================================================================
# ANIMATION
# =============================================================================

func _update_animation(delta: float) -> void:
	_run_timer += delta
	if _run_timer > RUN_ANIMATION_INTERVAL:
		_run_timer = 0.0
		_run_frame = (_run_frame + 1) % 2

	# Update texture based on current state
	match _state:
		State.IDLE:
			_sprite.texture = _textures.get("stand")
		State.RUNNING:
			_sprite.texture = _textures.get("walk1") if _run_frame == 0 else _textures.get("walk2")
		State.JUMPING, State.FALLING:
			_sprite.texture = _textures.get("jump")
		State.DUCKING:
			_sprite.texture = _textures.get("duck")
		State.DASHING:
			_sprite.texture = _textures.get("walk1")
		State.DEAD:
			_sprite.texture = _textures.get("hit")

	# Bob up and down while running on ground
	var running := _state == State.RUNNING and absf(velocity.x) > RUN_BOB_THRESHOLD
	_sprite.position.y = RUN_BOB_OFFSET if running and _run_frame == 0 else 0.0


func _update_squash_stretch() -> void:
	# Override squash/stretch when ducking
	if _state == State.DUCKING:
		_squash_stretch = DUCK_SQUASH
	
	_sprite.scale = _sprite.scale.lerp(_squash_stretch, SQUASH_LERP)
	
	# Only recover if not ducking
	if _state != State.DUCKING:
		_squash_stretch = _squash_stretch.lerp(Vector2.ONE, STRETCH_RECOVERY_LERP)

# =============================================================================
# DAMAGE & DEATH
# =============================================================================

## Called when player collides with an obstacle.
func hit_obstacle() -> void:
	if _state == State.DEAD or invincible:
		return
	ScreenEffects.shake_medium()
	ScreenEffects.flash_red()
	_die()


func _die() -> void:
	_change_state(State.DEAD)
	
	var tween := create_tween()
	tween.tween_property(self, "rotation", DEATH_ROTATION, DEATH_DURATION)
	tween.parallel().tween_property(self, "position:y", position.y + DEATH_FALL_DISTANCE, DEATH_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 0.0, DEATH_DURATION)
	
	died.emit()


## Returns the current state (for debugging/UI).
func get_state() -> State:
	return _state


## Returns the state name as a string (for debugging).
func get_state_name() -> String:
	return State.keys()[_state]
