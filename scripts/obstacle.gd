## Obstacle
## Represents a single obstacle that moves across the screen.
## Obstacles have different shapes, colors, and behaviors based on type.
extends Area2D

# =============================================================================
# CONSTANTS
# =============================================================================

const COLLISION_SIZE_RATIO: float = 0.8
const CIRCLE_SEGMENTS: int = 8
const OFF_SCREEN_LEFT: float = -100.0
const OFF_SCREEN_BOTTOM: float = 900.0

# Behavior constants
const FLYING_WAVE_FREQUENCY: float = 0.02
const FLYING_WAVE_AMPLITUDE: float = 30.0
const MOVE_WAVE_FREQUENCY: float = 0.05
const MOVE_WAVE_AMPLITUDE: float = 40.0
const BOUNCE_FREQUENCY: float = 0.03
const BOUNCE_AMPLITUDE: float = -30.0
const SWAY_FREQUENCY: float = 0.02
const SWAY_AMPLITUDE: float = 0.2
const SPIN_SPEED: float = 5.0
const FALL_SPEED: float = 100.0
const GLOW_BASE_ALPHA: float = 0.7
const GLOW_FREQUENCY: float = 0.1
const GLOW_AMPLITUDE: float = 0.3

# Rolling tire behavior (dramatic bouncing) - slower for mobile reaction time
const ROLL_FREQUENCY: float = 0.025  # Slower bounce cycle (was 0.04)
const ROLL_AMPLITUDE: float = -70.0  # Slightly lower bounces (was -80)
const ROLL_SPIN_SPEED: float = 6.0  # Slower spin (was 8.0)

# Shooting behavior (backpack shoots bananas)
const SHOOT_INTERVAL: float = 1.2  # Seconds between shots
const BANANA_SPEED: float = -250.0  # Upward velocity

# Signals for projectile spawning
signal spawn_projectile(projectile_type: String, pos: Vector2, velocity: Vector2)

# =============================================================================
# OBSTACLE CONFIGURATIONS
# =============================================================================

const CONFIGS: Dictionary = {
	# World 1: Road
	# Jump over: cone, backpack (shoots bananas), bike, hydrant, tire (bounces)
	# Duck under: barrier (construction barrier at head height), beam (steel beam)
	# Flat (harmless unless you trip): pothole, oil_spill
	# Projectile: banana (shot from backpack)
	"cone": {"color": Color(1, 0.5, 0), "width": 30, "height": 55, "ground": true, "shape": "triangle"},
	"pothole": {"color": Color(0.15, 0.15, 0.18), "width": 50, "height": 8, "ground": true, "shape": "flat"},
	"backpack": {"color": Color(0.3, 0.5, 0.8), "width": 35, "height": 40, "ground": true, "shape": "rect", "shoots": true},
	"bike": {"color": Color(0.2, 0.2, 0.8), "width": 55, "height": 45, "ground": true, "shape": "rect"},
	"hydrant": {"color": Color(0.9, 0.2, 0.2), "width": 25, "height": 45, "ground": true, "shape": "triangle"},
	"barrier": {"color": Color(1, 0.6, 0), "width": 60, "height": 25, "ground": true, "shape": "rect", "duck_under": true, "height_offset": -85},
	"toolbox": {"color": Color(0.8, 0.2, 0.2), "width": 40, "height": 25, "ground": true, "shape": "rect"},
	"beam": {"color": Color(0.6, 0.55, 0.5), "width": 80, "height": 15, "ground": true, "shape": "rect", "duck_under": true, "height_offset": -80},
	"tire": {"color": Color(0.15, 0.15, 0.15), "width": 40, "height": 40, "ground": true, "shape": "circle", "rolling": true},
	"oil_spill": {"color": Color(0.1, 0.1, 0.15), "width": 70, "height": 8, "ground": true, "shape": "flat", "slippery": true},
	"banana": {"color": Color(1.0, 0.9, 0.2), "width": 25, "height": 12, "ground": false, "shape": "banana", "projectile": true},
	
	# World 2: Soccer Field
	# Jump over: soccer_ball, water_bottle, sliding_player, goal_post, goalkeeper, corner_flag, referee, confetti_cannon
	# Duck under: flying_ball
	"soccer_ball": {"color": Color(1, 1, 1), "width": 30, "height": 30, "ground": true, "shape": "circle", "bounces": true},
	"water_bottle": {"color": Color(0.3, 0.7, 0.9), "width": 15, "height": 30, "ground": true, "shape": "rect"},
	"sliding_player": {"color": Color(0.2, 0.4, 0.8), "width": 60, "height": 25, "ground": true, "shape": "rect"},
	"goal_post": {"color": Color(1, 1, 1), "width": 15, "height": 70, "ground": true, "shape": "rect"},
	"goalkeeper": {"color": Color(0.2, 0.7, 0.3), "width": 45, "height": 55, "ground": true, "shape": "rect", "moves": true},
	"corner_flag": {"color": Color(1, 0.8, 0), "width": 10, "height": 50, "ground": true, "shape": "triangle"},
	"referee": {"color": Color(0.1, 0.1, 0.1), "width": 35, "height": 55, "ground": true, "shape": "rect"},
	"flying_ball": {"color": Color(1, 1, 1), "width": 28, "height": 28, "ground": false, "shape": "circle", "flying": true, "duck_under": true},
	"confetti_cannon": {"color": Color(0.8, 0.3, 0.8), "width": 40, "height": 50, "ground": true, "shape": "rect"},
	
	# World 3: Beach
	# Jump over: sandcastle, beach_ball, seashell, umbrella, cooler, crab, seaweed, slippery_rock, tide_wave, surfboard, wave, surfer, big_wave, debris
	# Duck under: flying_umbrella, jellyfish
	# Flat: towel
	"sandcastle": {"color": Color(0.9, 0.8, 0.5), "width": 50, "height": 55, "ground": true, "shape": "rect"},
	"beach_ball": {"color": Color(1, 0.3, 0.5), "width": 35, "height": 35, "ground": true, "shape": "circle", "bounces": true},
	"towel": {"color": Color(0.3, 0.6, 0.9), "width": 55, "height": 6, "ground": true, "shape": "flat"},
	"seashell": {"color": Color(1, 0.85, 0.7), "width": 25, "height": 20, "ground": true, "shape": "rect"},
	"umbrella": {"color": Color(1, 0.4, 0.4), "width": 55, "height": 65, "ground": true, "shape": "rect"},
	"cooler": {"color": Color(0.2, 0.5, 0.8), "width": 40, "height": 35, "ground": true, "shape": "rect"},
	"crab": {"color": Color(1, 0.4, 0.3), "width": 35, "height": 22, "ground": true, "shape": "crab", "moves": true},
	"jellyfish": {"color": Color(0.8, 0.5, 0.9, 0.7), "width": 30, "height": 40, "ground": false, "shape": "jellyfish", "flying": true, "duck_under": true},
	"seaweed": {"color": Color(0.2, 0.5, 0.3), "width": 25, "height": 50, "ground": true, "shape": "rect", "sways": true},
	"slippery_rock": {"color": Color(0.4, 0.45, 0.5), "width": 45, "height": 25, "ground": true, "shape": "rect", "slippery": true},
	"tide_wave": {"color": Color(0.3, 0.6, 0.8, 0.8), "width": 80, "height": 35, "ground": true, "shape": "rect"},
	"surfboard": {"color": Color(1, 0.9, 0.3), "width": 70, "height": 12, "ground": true, "shape": "flat"},
	"wave": {"color": Color(0.2, 0.5, 0.8), "width": 70, "height": 45, "ground": true, "shape": "rect"},
	"surfer": {"color": Color(0.9, 0.7, 0.5), "width": 40, "height": 55, "ground": true, "shape": "rect"},
	"big_wave": {"color": Color(0.15, 0.4, 0.7), "width": 100, "height": 70, "ground": true, "shape": "rect"},
	"debris": {"color": Color(0.5, 0.4, 0.3), "width": 45, "height": 30, "ground": true, "shape": "rect"},
	"flying_umbrella": {"color": Color(1, 0.3, 0.6), "width": 50, "height": 45, "ground": false, "shape": "rect", "flying": true, "duck_under": true},
	
	# World 4: Underwater
	# Jump over: coral, clam, kelp, sea_turtle, urchin, anchor, barrel, treasure_chest, chain, pressure_vent, thermal_vent
	# Duck under: small_fish, school_of_fish, shark, anglerfish, giant_squid, bioluminescent, crushing_pressure, ancient_creature
	"coral": {"color": Color(1, 0.5, 0.6), "width": 40, "height": 50, "ground": true, "shape": "rect"},
	"small_fish": {"color": Color(1, 0.7, 0.3), "width": 25, "height": 15, "ground": false, "shape": "fish", "flying": true, "duck_under": true},
	"clam": {"color": Color(0.6, 0.5, 0.7), "width": 35, "height": 25, "ground": true, "shape": "rect"},
	"kelp": {"color": Color(0.2, 0.5, 0.3), "width": 20, "height": 80, "ground": true, "shape": "rect", "sways": true},
	"sea_turtle": {"color": Color(0.3, 0.6, 0.4), "width": 50, "height": 35, "ground": true, "shape": "fish"},
	"school_of_fish": {"color": Color(0.5, 0.7, 0.9), "width": 60, "height": 40, "ground": false, "shape": "rect", "flying": true, "duck_under": true},
	"urchin": {"color": Color(0.2, 0.1, 0.3), "width": 30, "height": 30, "ground": true, "shape": "circle"},
	"anchor": {"color": Color(0.3, 0.3, 0.35), "width": 45, "height": 60, "ground": true, "shape": "rect"},
	"barrel": {"color": Color(0.5, 0.35, 0.2), "width": 35, "height": 45, "ground": true, "shape": "rect"},
	"shark": {"color": Color(0.4, 0.45, 0.5), "width": 70, "height": 35, "ground": false, "shape": "fish", "flying": true, "duck_under": true},
	"treasure_chest": {"color": Color(0.6, 0.45, 0.2), "width": 45, "height": 35, "ground": true, "shape": "rect"},
	"chain": {"color": Color(0.35, 0.35, 0.4), "width": 15, "height": 70, "ground": true, "shape": "rect"},
	"anglerfish": {"color": Color(0.2, 0.25, 0.3), "width": 45, "height": 35, "ground": false, "shape": "jellyfish", "flying": true, "glows": true, "duck_under": true},
	"giant_squid": {"color": Color(0.5, 0.3, 0.4), "width": 70, "height": 50, "ground": false, "shape": "rect", "flying": true, "duck_under": true},
	"pressure_vent": {"color": Color(0.3, 0.4, 0.5), "width": 30, "height": 60, "ground": true, "shape": "funnel"},
	"bioluminescent": {"color": Color(0.3, 0.8, 0.9, 0.7), "width": 25, "height": 25, "ground": false, "shape": "circle", "flying": true, "glows": true, "duck_under": true},
	"thermal_vent": {"color": Color(0.4, 0.3, 0.25), "width": 40, "height": 55, "ground": true, "shape": "funnel"},
	"crushing_pressure": {"color": Color(0.1, 0.15, 0.25, 0.5), "width": 80, "height": 100, "ground": false, "shape": "rect", "flying": true, "duck_under": true},
	"ancient_creature": {"color": Color(0.35, 0.3, 0.4), "width": 80, "height": 45, "ground": false, "shape": "rect", "flying": true, "duck_under": true},
	
	# World 5: Volcano
	# Jump over: steam_vent, hot_rock, ash_pile, crack, lava_pool, fire_geyser, molten_rock, lava_bubble, fire_wall, magma_wave, pyroclastic_flow, collapsing_ground, fire_tornado
	# Duck under: smoke_cloud, falling_stalactite, lava_bomb, meteor
	"steam_vent": {"color": Color(0.8, 0.8, 0.85, 0.6), "width": 35, "height": 50, "ground": true, "shape": "funnel"},
	"hot_rock": {"color": Color(0.4, 0.25, 0.2), "width": 40, "height": 35, "ground": true, "shape": "rect"},
	"ash_pile": {"color": Color(0.3, 0.3, 0.32), "width": 50, "height": 15, "ground": true, "shape": "flat"},
	"crack": {"color": Color(0.9, 0.4, 0.1), "width": 40, "height": 10, "ground": true, "shape": "flat"},
	"lava_pool": {"color": Color(1, 0.4, 0.1), "width": 60, "height": 10, "ground": true, "shape": "flat", "glows": true},
	"fire_geyser": {"color": Color(1, 0.5, 0.2), "width": 30, "height": 70, "ground": true, "shape": "funnel"},
	"molten_rock": {"color": Color(0.9, 0.35, 0.15), "width": 45, "height": 40, "ground": true, "shape": "rect", "glows": true},
	"smoke_cloud": {"color": Color(0.3, 0.3, 0.35, 0.7), "width": 60, "height": 50, "ground": false, "shape": "circle", "flying": true, "duck_under": true},
	"lava_bubble": {"color": Color(1, 0.5, 0.2), "width": 35, "height": 35, "ground": true, "shape": "circle", "glows": true},
	"falling_stalactite": {"color": Color(0.4, 0.35, 0.3), "width": 20, "height": 55, "ground": false, "shape": "triangle", "flying": true, "falls": true, "duck_under": true},
	"fire_wall": {"color": Color(1, 0.6, 0.2, 0.8), "width": 15, "height": 80, "ground": true, "shape": "rect"},
	"magma_wave": {"color": Color(1, 0.45, 0.15), "width": 90, "height": 40, "ground": true, "shape": "rect"},
	"lava_bomb": {"color": Color(0.9, 0.3, 0.1), "width": 35, "height": 35, "ground": false, "shape": "circle", "flying": true, "falls": true, "duck_under": true},
	"pyroclastic_flow": {"color": Color(0.5, 0.35, 0.3, 0.8), "width": 100, "height": 50, "ground": true, "shape": "rect"},
	"collapsing_ground": {"color": Color(0.3, 0.2, 0.15), "width": 70, "height": 15, "ground": true, "shape": "flat"},
	"fire_tornado": {"color": Color(1, 0.5, 0.2, 0.7), "width": 45, "height": 90, "ground": true, "shape": "funnel", "spins": true},
	"meteor": {"color": Color(0.5, 0.3, 0.25), "width": 50, "height": 50, "ground": false, "shape": "circle", "flying": true, "falls": true, "duck_under": true}
}

# =============================================================================
# EXPORTS
# =============================================================================

@export var obstacle_type: String = "cone"
@export var speed: float = 200.0

# =============================================================================
# STATE
# =============================================================================

var is_ground_obstacle: bool = true
var is_flying: bool = false
var is_duck_under: bool = false
var start_y: float = 0.0
var _config: Dictionary = {}

# Cached behavior flags (avoid dictionary lookups every frame)
var _behav_flying: bool = false
var _behav_moves: bool = false
var _behav_bounces: bool = false
var _behav_rolling: bool = false
var _behav_sways: bool = false
var _behav_spins: bool = false
var _behav_falls: bool = false
var _behav_glows: bool = false
var _behav_shoots: bool = false
var _behav_slippery: bool = false

# Shooting state (for backpacks)
var _shoot_timer: float = 0.0
var _can_shoot: bool = false

# Projectile state (for bananas)
var _is_projectile: bool = false
var _velocity: Vector2 = Vector2.ZERO

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _sprite: Sprite2D = $Sprite
@onready var _collision: CollisionShape2D = $CollisionShape2D

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_obstacle()


func _physics_process(delta: float) -> void:
	# Projectiles use velocity-based movement
	if _is_projectile:
		_apply_behaviors(delta)
		_check_off_screen()
		return
	
	# Normal obstacles move left
	position.x -= speed * delta
	_apply_behaviors(delta)
	_check_off_screen()

# =============================================================================
# SETUP
# =============================================================================

## External setup method called by spawner
func setup(obs_type: String, obs_speed: float, y_position: float) -> void:
	obstacle_type = obs_type
	speed = obs_speed
	position.y = y_position
	start_y = y_position
	call_deferred("_setup_obstacle")


## Sets up obstacle as a projectile with velocity
func setup_projectile(obs_type: String, obs_speed: float, y_position: float, vel: Vector2) -> void:
	setup(obs_type, obs_speed, y_position)
	_is_projectile = true
	_velocity = vel


## Resets obstacle state for reuse from pool
func reset() -> void:
	is_ground_obstacle = true
	is_flying = false
	is_duck_under = false
	start_y = 0.0
	_config = {}
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	_shoot_timer = 0.0
	_can_shoot = false
	_is_projectile = false
	_velocity = Vector2.ZERO
	# Reset cached behavior flags
	_behav_flying = false
	_behav_moves = false
	_behav_bounces = false
	_behav_rolling = false
	_behav_sways = false
	_behav_spins = false
	_behav_falls = false
	_behav_glows = false
	_behav_shoots = false
	_behav_slippery = false
	if _sprite:
		_sprite.rotation = 0.0
		_sprite.modulate = Color.WHITE
		_sprite.position = Vector2.ZERO
		_sprite.flip_v = false
		_sprite.scale = Vector2.ONE
	if _collision:
		_collision.position = Vector2.ZERO


# =============================================================================
# CUSTOM SPRITE MAPPING (Priority over Kenney)
# =============================================================================

const CUSTOM_SPRITE_MAP: Dictionary = {
	# World 1: Road
	"cone": "res://assets/sprites/obstacles/road/cone.png",
	"pothole": "res://assets/sprites/obstacles/road/pothole.png",
	"barrier": "res://assets/sprites/obstacles/road/barrier.png",
	"manhole": "res://assets/sprites/obstacles/road/manhole.png",
	# World 2: Soccer
	"soccer_ball": "res://assets/sprites/obstacles/soccer/soccer_ball.png",
	"flying_ball": "res://assets/sprites/obstacles/soccer/soccer_ball.png",
	"goal_post": "res://assets/sprites/obstacles/soccer/goal_post.png",
	"corner_flag": "res://assets/sprites/obstacles/soccer/training_cone.png",
	# World 3: Beach
	"beach_ball": "res://assets/sprites/obstacles/beach/beach_ball.png",
	"sandcastle": "res://assets/sprites/obstacles/beach/sand_castle.png",
	"crab": "res://assets/sprites/obstacles/beach/crab.png",
	"surfboard": "res://assets/sprites/obstacles/beach/surfboard.png",
	# World 4: Underwater
	"jellyfish": "res://assets/sprites/obstacles/underwater/jellyfish.png",
	"anchor": "res://assets/sprites/obstacles/underwater/anchor.png",
	"coral": "res://assets/sprites/obstacles/underwater/coral.png",
	"shark": "res://assets/sprites/obstacles/underwater/shark_fin.png",
	# World 5: Volcano
	"meteor": "res://assets/sprites/obstacles/volcano/meteor.png",
	"fire_geyser": "res://assets/sprites/obstacles/volcano/lava_geyser.png",
	"lava_bubble": "res://assets/sprites/obstacles/volcano/lava_geyser.png",
	"falling_stalactite": "res://assets/sprites/obstacles/volcano/obsidian_spike.png",
}

# =============================================================================
# KENNEY SPRITE MAPPING (Fallback)
# =============================================================================

const SPRITE_MAP: Dictionary = {
	# World 1: Road
	"cone": {"texture": "res://assets/kenney/tiles/spikes.png", "tint": Color(1, 0.6, 0.2)},
	"tire": {"texture": "res://assets/kenney/enemies/saw.png"},
	"barrier": {"texture": "res://assets/kenney/tiles/fence.png"},
	"backpack": {"texture": "res://assets/kenney/tiles/boxItem.png", "tint": Color(0.5, 0.6, 0.9)},
	"bike": {"texture": "res://assets/kenney/tiles/boxCrate.png", "tint": Color(0.3, 0.3, 0.8)},
	"hydrant": {"texture": "res://assets/kenney/tiles/boxCrate_warning.png", "tint": Color(0.9, 0.3, 0.3)},
	"oil_spill": {"texture": "res://assets/kenney/tiles/water.png", "tint": Color(0.15, 0.15, 0.2)},
	"beam": {"texture": "res://assets/kenney/tiles/bridgeA.png"},
	"toolbox": {"texture": "res://assets/kenney/tiles/boxCrate.png", "tint": Color(0.8, 0.2, 0.2)},
	# World 2: Soccer
	"soccer_ball": {"texture": "res://assets/kenney/enemies/slimeBlock.png", "tint": Color(1, 1, 1)},
	"goalkeeper": {"texture": "res://assets/kenney/players/alienGreen_stand.png"},
	"referee": {"texture": "res://assets/kenney/players/alienBeige_stand.png"},
	"sliding_player": {"texture": "res://assets/kenney/players/alienBlue_duck.png"},
	"flying_ball": {"texture": "res://assets/kenney/enemies/slimeBlock.png", "tint": Color(1, 1, 1)},
	"corner_flag": {"texture": "res://assets/kenney/items/flagYellow1.png"},
	"confetti_cannon": {"texture": "res://assets/kenney/tiles/bomb.png", "tint": Color(0.8, 0.3, 0.8)},
	"goal_post": {"texture": "res://assets/kenney/tiles/chain.png", "tint": Color(1, 1, 1)},
	"water_bottle": {"texture": "res://assets/kenney/tiles/boxCrate_single.png", "tint": Color(0.3, 0.7, 0.9)},
	# World 3: Beach
	"crab": {"texture": "res://assets/kenney/enemies/ladybug.png", "tint": Color(1, 0.5, 0.3)},
	"jellyfish": {"texture": "res://assets/kenney/enemies/slimePurple.png"},
	"shark": {"texture": "res://assets/kenney/enemies/fishBlue.png", "tint": Color(0.5, 0.5, 0.55)},
	"beach_ball": {"texture": "res://assets/kenney/enemies/slimeGreen.png", "tint": Color(1, 0.5, 0.7)},
	"sandcastle": {"texture": "res://assets/kenney/tiles/boxCrate.png", "tint": Color(0.9, 0.8, 0.5)},
	"seashell": {"texture": "res://assets/kenney/enemies/snail_shell.png"},
	"umbrella": {"texture": "res://assets/kenney/tiles/mushroomRed.png"},
	"surfboard": {"texture": "res://assets/kenney/tiles/bridgeB.png", "tint": Color(1, 0.9, 0.3)},
	"seaweed": {"texture": "res://assets/kenney/tiles/plantPurple.png", "tint": Color(0.3, 0.6, 0.3)},
	"flying_umbrella": {"texture": "res://assets/kenney/tiles/mushroomRed.png", "tint": Color(1, 0.3, 0.6)},
	# World 4: Underwater
	"small_fish": {"texture": "res://assets/kenney/enemies/fishPink.png"},
	"sea_turtle": {"texture": "res://assets/kenney/enemies/frog.png", "tint": Color(0.3, 0.6, 0.4)},
	"coral": {"texture": "res://assets/kenney/tiles/mushroomBrown.png", "tint": Color(1, 0.5, 0.6)},
	"urchin": {"texture": "res://assets/kenney/enemies/saw.png", "tint": Color(0.3, 0.15, 0.4)},
	"clam": {"texture": "res://assets/kenney/enemies/snail_shell.png", "tint": Color(0.6, 0.5, 0.7)},
	"anglerfish": {"texture": "res://assets/kenney/enemies/fishGreen.png", "tint": Color(0.2, 0.25, 0.3)},
	"giant_squid": {"texture": "res://assets/kenney/enemies/slimePurple.png", "tint": Color(0.5, 0.3, 0.4)},
	"anchor": {"texture": "res://assets/kenney/tiles/weight.png"},
	"barrel": {"texture": "res://assets/kenney/tiles/boxCrate.png", "tint": Color(0.5, 0.35, 0.2)},
	"treasure_chest": {"texture": "res://assets/kenney/tiles/boxCoin.png"},
	"bioluminescent": {"texture": "res://assets/kenney/items/gemGreen.png"},
	"chain": {"texture": "res://assets/kenney/tiles/chain.png"},
	"school_of_fish": {"texture": "res://assets/kenney/enemies/fishBlue.png", "tint": Color(0.5, 0.7, 0.9)},
	"kelp": {"texture": "res://assets/kenney/tiles/plantPurple.png", "tint": Color(0.2, 0.5, 0.3)},
	# World 5: Volcano
	"lava_pool": {"texture": "res://assets/kenney/tiles/lava.png"},
	"lava_bubble": {"texture": "res://assets/kenney/tiles/lavaTop_high.png"},
	"meteor": {"texture": "res://assets/kenney/tiles/rock.png", "tint": Color(0.6, 0.3, 0.25)},
	"hot_rock": {"texture": "res://assets/kenney/tiles/rock.png", "tint": Color(0.35, 0.25, 0.2)},
	"fire_geyser": {"texture": "res://assets/kenney/tiles/torch1.png"},
	"steam_vent": {"texture": "res://assets/kenney/tiles/torch2.png", "tint": Color(0.8, 0.8, 0.85)},
	"falling_stalactite": {"texture": "res://assets/kenney/tiles/spikes.png", "flip_v": true},
	"smoke_cloud": {"texture": "res://assets/kenney/enemies/slimeBlock.png", "tint": Color(0.4, 0.4, 0.45, 0.7)},
	"fire_tornado": {"texture": "res://assets/kenney/tiles/torch2.png", "tint": Color(1, 0.5, 0.2)},
	"lava_bomb": {"texture": "res://assets/kenney/tiles/rock.png", "tint": Color(0.9, 0.3, 0.1)},
	"molten_rock": {"texture": "res://assets/kenney/tiles/rock.png", "tint": Color(0.9, 0.35, 0.15)},
	"fire_wall": {"texture": "res://assets/kenney/tiles/torch1.png", "tint": Color(1, 0.6, 0.2)},
}

# Fallback texture for unmapped obstacles
const FALLBACK_TEXTURE: String = "res://assets/kenney/tiles/boxCrate_single.png"

# =============================================================================
# PRELOADED TEXTURE CACHE (avoids runtime load() calls)
# =============================================================================

# Custom sprite textures (preloaded)
const PRELOADED_CUSTOM: Dictionary = {
	# World 1: Road
	"cone": preload("res://assets/sprites/obstacles/road/cone.png"),
	"pothole": preload("res://assets/sprites/obstacles/road/pothole.png"),
	"barrier": preload("res://assets/sprites/obstacles/road/barrier.png"),
	"manhole": preload("res://assets/sprites/obstacles/road/manhole.png"),
	# World 2: Soccer
	"soccer_ball": preload("res://assets/sprites/obstacles/soccer/soccer_ball.png"),
	"goal_post": preload("res://assets/sprites/obstacles/soccer/goal_post.png"),
	"corner_flag": preload("res://assets/sprites/obstacles/soccer/training_cone.png"),
	# World 3: Beach
	"beach_ball": preload("res://assets/sprites/obstacles/beach/beach_ball.png"),
	"sandcastle": preload("res://assets/sprites/obstacles/beach/sand_castle.png"),
	"crab": preload("res://assets/sprites/obstacles/beach/crab.png"),
	"surfboard": preload("res://assets/sprites/obstacles/beach/surfboard.png"),
	# World 4: Underwater
	"jellyfish": preload("res://assets/sprites/obstacles/underwater/jellyfish.png"),
	"anchor": preload("res://assets/sprites/obstacles/underwater/anchor.png"),
	"coral": preload("res://assets/sprites/obstacles/underwater/coral.png"),
	"shark": preload("res://assets/sprites/obstacles/underwater/shark_fin.png"),
	# World 5: Volcano
	"meteor": preload("res://assets/sprites/obstacles/volcano/meteor.png"),
	"fire_geyser": preload("res://assets/sprites/obstacles/volcano/lava_geyser.png"),
	"falling_stalactite": preload("res://assets/sprites/obstacles/volcano/obsidian_spike.png"),
}

# Kenney fallback textures (preloaded for common obstacles)
const PRELOADED_KENNEY: Dictionary = {
	"boxCrate_single": preload("res://assets/kenney/tiles/boxCrate_single.png"),
	"spikes": preload("res://assets/kenney/tiles/spikes.png"),
	"saw": preload("res://assets/kenney/enemies/saw.png"),
	"fence": preload("res://assets/kenney/tiles/fence.png"),
	"boxItem": preload("res://assets/kenney/tiles/boxItem.png"),
	"boxCrate": preload("res://assets/kenney/tiles/boxCrate.png"),
	"boxCrate_warning": preload("res://assets/kenney/tiles/boxCrate_warning.png"),
	"water": preload("res://assets/kenney/tiles/water.png"),
	"bridgeA": preload("res://assets/kenney/tiles/bridgeA.png"),
	"slimeBlock": preload("res://assets/kenney/enemies/slimeBlock.png"),
	"alienGreen_stand": preload("res://assets/kenney/players/alienGreen_stand.png"),
	"alienBeige_stand": preload("res://assets/kenney/players/alienBeige_stand.png"),
	"alienBlue_duck": preload("res://assets/kenney/players/alienBlue_duck.png"),
	"flagYellow1": preload("res://assets/kenney/items/flagYellow1.png"),
	"bomb": preload("res://assets/kenney/tiles/bomb.png"),
	"chain": preload("res://assets/kenney/tiles/chain.png"),
	"ladybug": preload("res://assets/kenney/enemies/ladybug.png"),
	"slimePurple": preload("res://assets/kenney/enemies/slimePurple.png"),
	"fishBlue": preload("res://assets/kenney/enemies/fishBlue.png"),
	"slimeGreen": preload("res://assets/kenney/enemies/slimeGreen.png"),
	"snail_shell": preload("res://assets/kenney/enemies/snail_shell.png"),
	"mushroomRed": preload("res://assets/kenney/tiles/mushroomRed.png"),
	"bridgeB": preload("res://assets/kenney/tiles/bridgeB.png"),
	"plantPurple": preload("res://assets/kenney/tiles/plantPurple.png"),
	"fishPink": preload("res://assets/kenney/enemies/fishPink.png"),
	"frog": preload("res://assets/kenney/enemies/frog.png"),
	"mushroomBrown": preload("res://assets/kenney/tiles/mushroomBrown.png"),
	"fishGreen": preload("res://assets/kenney/enemies/fishGreen.png"),
	"weight": preload("res://assets/kenney/tiles/weight.png"),
	"boxCoin": preload("res://assets/kenney/tiles/boxCoin.png"),
	"gemGreen": preload("res://assets/kenney/items/gemGreen.png"),
	"lava": preload("res://assets/kenney/tiles/lava.png"),
	"lavaTop_high": preload("res://assets/kenney/tiles/lavaTop_high.png"),
	"rock": preload("res://assets/kenney/tiles/rock.png"),
	"torch1": preload("res://assets/kenney/tiles/torch1.png"),
	"torch2": preload("res://assets/kenney/tiles/torch2.png"),
}

# Runtime texture cache for textures not preloaded
var _texture_cache: Dictionary = {}

## Gets a texture, using preloaded cache first, then runtime cache
func _get_texture(path: String) -> Texture2D:
	# Check preloaded custom sprites by obstacle type
	if PRELOADED_CUSTOM.has(obstacle_type):
		return PRELOADED_CUSTOM[obstacle_type]

	# Check preloaded Kenney textures by filename
	var filename: String = path.get_file().get_basename()
	if PRELOADED_KENNEY.has(filename):
		return PRELOADED_KENNEY[filename]

	# Fall back to runtime cache
	if not _texture_cache.has(path):
		if ResourceLoader.exists(path):
			_texture_cache[path] = load(path)
		else:
			push_warning("[Obstacle] Texture not found: %s (type: %s)" % [path, obstacle_type])
			_texture_cache[path] = null
	return _texture_cache[path]

func _setup_obstacle() -> void:
	if not CONFIGS.has(obstacle_type):
		push_warning("Unknown obstacle type: %s, defaulting to cone" % obstacle_type)
		obstacle_type = "cone"

	_config = CONFIGS[obstacle_type]

	# Load sprite texture - check custom sprites first, then Kenney fallback
	var sprite_info: Dictionary = {}
	var texture_path: String = FALLBACK_TEXTURE

	if CUSTOM_SPRITE_MAP.has(obstacle_type):
		# Use custom sprite (no tint needed - already correct colors)
		texture_path = CUSTOM_SPRITE_MAP[obstacle_type]
	else:
		# Fall back to Kenney sprites
		sprite_info = SPRITE_MAP.get(obstacle_type, {})
		texture_path = sprite_info.get("texture", FALLBACK_TEXTURE)

	_sprite.texture = _get_texture(texture_path)

	# Scale texture to a reasonable game size (Kenney tiles are ~128px, we want ~50-80px obstacles)
	if _sprite.texture:
		var tex_size: Vector2 = _sprite.texture.get_size()
		# Use the larger dimension to determine scale, targeting config size
		var target_size: float = maxf(_config.width, _config.height)
		var tex_max: float = maxf(tex_size.x, tex_size.y)
		var base_scale: float = (target_size / tex_max) * 1.2  # 1.2x multiplier for better visibility
		_sprite.scale = Vector2(base_scale, base_scale)

	# Apply tint color
	var tint: Color = sprite_info.get("tint", Color.WHITE)
	if tint != Color.WHITE:
		_sprite.modulate = tint
	else:
		_sprite.modulate = _config.color if sprite_info.is_empty() else Color.WHITE

	# Apply vertical flip if specified
	if sprite_info.get("flip_v", false):
		_sprite.flip_v = true

	# Derive collision from rendered sprite size (not raw config dimensions)
	if _sprite.texture:
		var rendered_size := _sprite.texture.get_size() * _sprite.scale.abs()
		_setup_collision(rendered_size.x, rendered_size.y)
	else:
		_setup_collision(_config.width, _config.height)

	is_ground_obstacle = _config.ground
	is_flying = _config.get("flying", false)
	is_duck_under = _config.get("duck_under", false)
	_is_projectile = _config.get("projectile", false)

	# Cache behavior flags (avoid dictionary lookups every frame)
	_behav_flying = _config.get("flying", false)
	_behav_moves = _config.get("moves", false)
	_behav_bounces = _config.get("bounces", false)
	_behav_rolling = _config.get("rolling", false)
	_behav_sways = _config.get("sways", false)
	_behav_spins = _config.get("spins", false)
	_behav_falls = _config.get("falls", false)
	_behav_glows = _config.get("glows", false)
	_behav_shoots = _config.get("shoots", false)
	_behav_slippery = _config.get("slippery", false)

	# Set up shooting behavior
	if _behav_shoots:
		_can_shoot = true
		_shoot_timer = SHOOT_INTERVAL * randf_range(0.5, 1.0)

	# Apply height offset for duck_under obstacles
	var height_offset: float = _config.get("height_offset", 0.0)
	if height_offset != 0.0:
		_sprite.position.y = height_offset
		_collision.position.y = height_offset


func _setup_collision(width: float, height: float) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width * COLLISION_SIZE_RATIO, height * COLLISION_SIZE_RATIO)
	_collision.shape = shape

# =============================================================================
# BEHAVIORS
# =============================================================================

func _apply_behaviors(delta: float) -> void:
	# Projectile movement (bananas fly upward then fall)
	if _is_projectile:
		_velocity.y += 400.0 * delta  # Gravity
		position += _velocity * delta
		_sprite.rotation += delta * 3.0  # Spin while flying
		return

	# Use cached behavior flags (no dictionary lookups)
	if _behav_flying:
		position.y = start_y + sin(position.x * FLYING_WAVE_FREQUENCY) * FLYING_WAVE_AMPLITUDE

	if _behav_moves:
		position.y += sin(position.x * MOVE_WAVE_FREQUENCY) * MOVE_WAVE_AMPLITUDE * delta

	if _behav_bounces:
		position.y = start_y + absf(sin(position.x * BOUNCE_FREQUENCY)) * BOUNCE_AMPLITUDE

	# Rolling tires - big dramatic bounces with spin
	if _behav_rolling:
		position.y = start_y + absf(sin(position.x * ROLL_FREQUENCY)) * ROLL_AMPLITUDE
		_sprite.rotation += delta * ROLL_SPIN_SPEED

	if _behav_sways:
		_sprite.rotation = sin(position.x * SWAY_FREQUENCY) * SWAY_AMPLITUDE

	if _behav_spins:
		_sprite.rotation += delta * SPIN_SPEED

	if _behav_falls:
		position.y += delta * FALL_SPEED

	if _behav_glows:
		_sprite.modulate.a = GLOW_BASE_ALPHA + sin(position.x * GLOW_FREQUENCY) * GLOW_AMPLITUDE

	# Shooting (backpacks shoot bananas)
	if _behav_shoots and _can_shoot:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_shoot_timer = SHOOT_INTERVAL
			var shoot_pos := global_position + Vector2(0, -30)  # Above backpack
			spawn_projectile.emit("banana", shoot_pos, Vector2(-speed * 0.3, BANANA_SPEED))


func _check_off_screen() -> void:
	# Check left and bottom bounds (normal obstacles)
	if position.x < OFF_SCREEN_LEFT or position.y > OFF_SCREEN_BOTTOM:
		release_to_pool()
		return
	
	# Projectiles can also go off the top of the screen
	if _is_projectile and position.y < -100.0:
		release_to_pool()


## Returns this obstacle to the object pool for reuse
func release_to_pool() -> void:
	if is_inside_tree():
		ObjectPool.release_obstacle(self)

# =============================================================================
# COLLISION
# =============================================================================

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Slippery obstacles don't cause damage (uses cached flag)
	if _behav_slippery:
		return

	# Duck-under obstacles can be avoided by ducking
	if is_duck_under and "is_ducking" in body and body.is_ducking:
		return

	AudioManager.play_hit()
	body.hit_obstacle()
