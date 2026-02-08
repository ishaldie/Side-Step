## Powerup Collectible
## Moves across the screen and grants a temporary effect when collected.
class_name Powerup
extends Area2D

# =============================================================================
# TYPE ENUM & CONFIGS
# =============================================================================

enum Type { MAGNET, SHIELD, SPEED_BOOST }

const CONFIGS: Dictionary = {
	Type.MAGNET: {
		"duration": 5.0,
		"sprite_path": "res://assets/sprites/powerups/magnet.png",
		"magnet_radius": 150.0,
	},
	Type.SHIELD: {
		"duration": 4.0,
		"sprite_path": "res://assets/sprites/powerups/shield.png",
	},
	Type.SPEED_BOOST: {
		"duration": 3.0,
		"sprite_path": "res://assets/sprites/powerups/speed_bolt.png",
		"speed_multiplier": 1.5,
	},
}

# =============================================================================
# CONSTANTS
# =============================================================================

const BOB_SPEED: float = 3.0
const BOB_AMPLITUDE: float = 6.0
const OFF_SCREEN_X: float = -50.0
const SPRITE_SCALE: Vector2 = Vector2(0.5, 0.5)

const COLLECT_SCALE: Vector2 = Vector2(1.8, 1.8)
const COLLECT_DURATION: float = 0.15

# =============================================================================
# STATE
# =============================================================================

var powerup_type: Type = Type.MAGNET
var speed: float = 200.0

var _bob_offset: float = 0.0
var _start_y: float = 0.0
var _collected: bool = false

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _sprite: Sprite2D = $Sprite
@onready var _collision: CollisionShape2D = $CollisionShape

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_start_y = position.y
	_bob_offset = randf() * TAU
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _collected:
		return

	position.x -= speed * delta

	_bob_offset += delta * BOB_SPEED
	position.y = _start_y + sin(_bob_offset) * BOB_AMPLITUDE

	if position.x < OFF_SCREEN_X:
		release_to_pool()

# =============================================================================
# PUBLIC API
# =============================================================================

## Configure this powerup for spawning.
func setup(type: Type, move_speed: float, y_position: float) -> void:
	powerup_type = type
	speed = move_speed
	position.y = y_position
	_start_y = y_position

	var config = CONFIGS[type]
	if _sprite and ResourceLoader.exists(config.sprite_path):
		_sprite.texture = load(config.sprite_path)
		_sprite.scale = SPRITE_SCALE


## Reset for pool reuse.
func reset() -> void:
	_collected = false
	_bob_offset = randf() * TAU
	scale = Vector2.ONE
	modulate = Color.WHITE
	visible = true
	rotation = 0.0
	if _sprite:
		_sprite.rotation = 0.0
		_sprite.modulate = Color.WHITE
		_sprite.position = Vector2.ZERO
		_sprite.scale = SPRITE_SCALE


## Return to pool.
func release_to_pool() -> void:
	if is_inside_tree():
		get_parent().remove_child(self)

# =============================================================================
# COLLISION
# =============================================================================

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return

	if not body.is_in_group("player"):
		return

	_collected = true
	AudioManager.play_coin()  # Reuse coin sound for now
	EventBus.powerup_collected.emit(powerup_type)

	# Collect animation
	var tween := create_tween()
	tween.tween_property(self, "scale", COLLECT_SCALE, COLLECT_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 0.0, COLLECT_DURATION)
	tween.tween_callback(release_to_pool)
