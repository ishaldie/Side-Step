## Coin Collectible
## Moves across the screen and awards points when collected.
extends Area2D

# =============================================================================
# CONSTANTS
# =============================================================================

const BOB_SPEED: float = 4.0
const BOB_AMPLITUDE: float = 8.0
const SPIN_SPEED: float = 3.0
const OFF_SCREEN_X: float = -50.0

const COLLECT_SCALE: Vector2 = Vector2(1.5, 1.5)
const COLLECT_RISE: float = 30.0
const COLLECT_DURATION: float = 0.1

# Preloaded texture (avoids runtime load())
const COIN_TEXTURE: Texture2D = preload("res://assets/kenney/items/coinGold.png")
const COIN_SCALE: Vector2 = Vector2(0.4, 0.4)

# =============================================================================
# EXPORTS
# =============================================================================

@export var value: int = 1
@export var speed: float = 200.0

# =============================================================================
# STATE
# =============================================================================

var _bob_offset: float = 0.0
var _start_y: float = 0.0
var _collected: bool = false

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _sprite: Sprite2D = $Sprite

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_start_y = position.y
	_bob_offset = randf() * TAU
	body_entered.connect(_on_body_entered)
	# Use preloaded texture (no runtime load())
	_sprite.texture = COIN_TEXTURE
	_sprite.scale = COIN_SCALE


func _physics_process(delta: float) -> void:
	if _collected:
		return
	
	position.x -= speed * delta
	
	_bob_offset += delta * BOB_SPEED
	position.y = _start_y + sin(_bob_offset) * BOB_AMPLITUDE
	
	_sprite.rotation += delta * SPIN_SPEED
	
	if position.x < OFF_SCREEN_X:
		release_to_pool()


## Returns this coin to the object pool for reuse
func release_to_pool() -> void:
	if is_inside_tree():
		ObjectPool.release_coin(self)


## Resets coin state for reuse from pool
func reset() -> void:
	_collected = false
	_bob_offset = randf() * TAU
	scale = Vector2.ONE
	modulate = Color.WHITE
	visible = true
	rotation = 0.0
	# Reset sprite (uses cached @onready reference)
	if _sprite:
		_sprite.rotation = 0.0
		_sprite.modulate = Color.WHITE
		_sprite.position = Vector2.ZERO
		_sprite.scale = COIN_SCALE

# =============================================================================
# PUBLIC
# =============================================================================

## Called by spawner to configure the coin
func setup(coin_speed: float, y_position: float, coin_value: int = 1) -> void:
	speed = coin_speed
	position.y = y_position
	_start_y = y_position
	value = coin_value

# =============================================================================
# COLLISION
# =============================================================================

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	
	if not body.is_in_group("player"):
		return
	
	_collected = true
	GameManager.collect_coin(value)
	AudioManager.play_coin()
	
	# Notify tutorial
	if TutorialManager:
		TutorialManager.on_coin_collected()
	
	var tween := create_tween()
	tween.tween_property(self, "scale", COLLECT_SCALE, COLLECT_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 0.0, COLLECT_DURATION)
	tween.parallel().tween_property(self, "position:y", position.y - COLLECT_RISE, COLLECT_DURATION)
	tween.tween_callback(release_to_pool)
