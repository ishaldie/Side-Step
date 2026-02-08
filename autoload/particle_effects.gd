## ParticleEffects Autoload
## Provides factory methods for spawning one-shot particle effects.
## Uses CPUParticles2D for mobile compatibility.
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

# Coin collect — gold burst
const COIN_PARTICLE_COUNT: int = 12
const COIN_LIFETIME: float = 0.4
const COIN_COLOR: Color = Color(1.0, 0.85, 0.1)  # Gold
const COIN_SPREAD: float = 180.0
const COIN_VELOCITY: float = 80.0
const COIN_GRAVITY: float = 200.0

# Player hit — red/orange impact
const HIT_PARTICLE_COUNT: int = 16
const HIT_LIFETIME: float = 0.3
const HIT_COLOR: Color = Color(1.0, 0.3, 0.1)  # Red-orange
const HIT_SPREAD: float = 180.0
const HIT_VELOCITY: float = 100.0
const HIT_GRAVITY: float = 150.0

# Player death — larger burst
const DEATH_PARTICLE_COUNT: int = 32
const DEATH_LIFETIME: float = 0.6
const DEATH_COLOR: Color = Color(1.0, 0.15, 0.1)  # Deep red
const DEATH_SPREAD: float = 180.0
const DEATH_VELOCITY: float = 140.0
const DEATH_GRAVITY: float = 120.0

# =============================================================================
# PUBLIC API
# =============================================================================

## Spawn gold coin-collect particles at the given position.
func spawn_coin_particles(pos: Vector2) -> CPUParticles2D:
	return _spawn_effect(pos, COIN_PARTICLE_COUNT, COIN_LIFETIME, COIN_COLOR,
		COIN_SPREAD, COIN_VELOCITY, COIN_GRAVITY)


## Spawn red/orange hit-impact particles at the given position.
func spawn_hit_particles(pos: Vector2) -> CPUParticles2D:
	return _spawn_effect(pos, HIT_PARTICLE_COUNT, HIT_LIFETIME, HIT_COLOR,
		HIT_SPREAD, HIT_VELOCITY, HIT_GRAVITY)


## Spawn large death-burst particles at the given position.
func spawn_death_particles(pos: Vector2) -> CPUParticles2D:
	return _spawn_effect(pos, DEATH_PARTICLE_COUNT, DEATH_LIFETIME, DEATH_COLOR,
		DEATH_SPREAD, DEATH_VELOCITY, DEATH_GRAVITY)

# =============================================================================
# INTERNAL
# =============================================================================

func _spawn_effect(pos: Vector2, amount: int, lifetime: float, color: Color,
		spread: float, velocity: float, gravity: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 1.0
	p.color = color
	p.spread = spread
	p.initial_velocity_min = velocity * 0.5
	p.initial_velocity_max = velocity
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 4.0
	p.direction = Vector2(0, -1)
	p.global_position = pos
	p.emitting = true

	# Add to scene tree (guard against null during scene transitions)
	var scene := get_tree().current_scene
	if not scene:
		p.queue_free()
		return p

	scene.add_child(p)

	# Auto-free after particles finish
	get_tree().create_timer(lifetime + 0.1).timeout.connect(p.queue_free)

	return p
