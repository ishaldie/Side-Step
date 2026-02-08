## Unit Tests for Obstacle Boundary/Collision Alignment
## Validates that collision shapes match rendered sprite bounds
extends GutTest

const OBSTACLE_SCENE = preload("res://scenes/obstacle.tscn")
const POSITIONING_CONFIG = preload("res://scripts/positioning_config.gd")
const COLLISION_SIZE_RATIO: float = 0.8
# Tolerance for floating point comparison (pixels)
const TOLERANCE: float = 2.0

var _configs: Dictionary
var _obstacle: Area2D

func before_all():
	var obstacle_script = load("res://scripts/obstacle.gd")
	_configs = obstacle_script.CONFIGS

func before_each():
	_obstacle = OBSTACLE_SCENE.instantiate()
	add_child_autofree(_obstacle)
	await get_tree().process_frame

func after_each():
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# CORE BOUNDARY MATCHING TESTS
# =============================================================================

func test_collision_width_matches_rendered_sprite_width():
	# For a representative set of obstacles, collision width should track
	# the rendered sprite width (not raw config width)
	var test_types = ["cone", "barrier", "soccer_ball", "shark", "meteor"]
	for obs_type in test_types:
		if not _configs.has(obs_type):
			continue
		_obstacle.reset()
		_obstacle.setup(obs_type, 200.0, 650.0)
		await get_tree().process_frame

		var sprite: Sprite2D = _obstacle.get_node("Sprite")
		var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
		if not sprite or not sprite.texture or not collision or not collision.shape:
			continue

		var rendered_width: float = sprite.texture.get_size().x * absf(sprite.scale.x)
		var shape: RectangleShape2D = collision.shape as RectangleShape2D
		if not shape:
			continue

		var expected_collision_width: float = rendered_width * COLLISION_SIZE_RATIO
		assert_almost_eq(
			shape.size.x,
			expected_collision_width,
			TOLERANCE,
			"Obstacle '%s' collision width (%.1f) should match rendered width * ratio (%.1f)" % [
				obs_type, shape.size.x, expected_collision_width
			]
		)

func test_collision_height_matches_rendered_sprite_height():
	var test_types = ["cone", "barrier", "soccer_ball", "shark", "meteor"]
	for obs_type in test_types:
		if not _configs.has(obs_type):
			continue
		_obstacle.reset()
		_obstacle.setup(obs_type, 200.0, 650.0)
		await get_tree().process_frame

		var sprite: Sprite2D = _obstacle.get_node("Sprite")
		var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
		if not sprite or not sprite.texture or not collision or not collision.shape:
			continue

		var rendered_height: float = sprite.texture.get_size().y * absf(sprite.scale.y)
		var shape: RectangleShape2D = collision.shape as RectangleShape2D
		if not shape:
			continue

		var expected_collision_height: float = rendered_height * COLLISION_SIZE_RATIO
		assert_almost_eq(
			shape.size.y,
			expected_collision_height,
			TOLERANCE,
			"Obstacle '%s' collision height (%.1f) should match rendered height * ratio (%.1f)" % [
				obs_type, shape.size.y, expected_collision_height
			]
		)

func test_all_obstacles_collision_within_rendered_bounds():
	# No obstacle's collision should exceed its rendered sprite bounds
	for obs_type in _configs:
		if _configs[obs_type].get("projectile", false):
			continue  # Skip projectiles
		_obstacle.reset()
		_obstacle.setup(obs_type, 200.0, 650.0)
		await get_tree().process_frame

		var sprite: Sprite2D = _obstacle.get_node("Sprite")
		var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
		if not sprite or not sprite.texture or not collision or not collision.shape:
			continue

		var rendered_w: float = sprite.texture.get_size().x * absf(sprite.scale.x)
		var rendered_h: float = sprite.texture.get_size().y * absf(sprite.scale.y)
		var shape: RectangleShape2D = collision.shape as RectangleShape2D
		if not shape:
			continue

		assert_true(
			shape.size.x <= rendered_w + TOLERANCE,
			"Obstacle '%s' collision width (%.1f) exceeds rendered width (%.1f)" % [
				obs_type, shape.size.x, rendered_w
			]
		)
		assert_true(
			shape.size.y <= rendered_h + TOLERANCE,
			"Obstacle '%s' collision height (%.1f) exceeds rendered height (%.1f)" % [
				obs_type, shape.size.y, rendered_h
			]
		)

# =============================================================================
# COLLISION RATIO CONSISTENCY
# =============================================================================

func test_collision_uses_collision_size_ratio():
	# For obstacles with square textures (like Kenney 128x128), the collision
	# should be exactly rendered_size * COLLISION_SIZE_RATIO
	# Using tire (Kenney saw.png 128x128, config 40x40)
	if not _configs.has("tire"):
		pass_test("tire not in configs")
		return
	_obstacle.reset()
	_obstacle.setup("tire", 200.0, 650.0)
	await get_tree().process_frame

	var sprite: Sprite2D = _obstacle.get_node("Sprite")
	var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
	var shape: RectangleShape2D = collision.shape as RectangleShape2D

	if sprite and sprite.texture and shape:
		var rendered_w: float = sprite.texture.get_size().x * absf(sprite.scale.x)
		var rendered_h: float = sprite.texture.get_size().y * absf(sprite.scale.y)
		assert_almost_eq(
			shape.size.x,
			rendered_w * COLLISION_SIZE_RATIO,
			TOLERANCE,
			"Tire collision width should be rendered_width * 0.8"
		)
		assert_almost_eq(
			shape.size.y,
			rendered_h * COLLISION_SIZE_RATIO,
			TOLERANCE,
			"Tire collision height should be rendered_height * 0.8"
		)

func test_non_square_texture_collision_aspect_ratio():
	# For obstacles with non-square textures, collision aspect ratio
	# should match the rendered sprite's aspect ratio
	# Cone: custom sprite 110x132, config 30x55
	if not _configs.has("cone"):
		pass_test("cone not in configs")
		return
	_obstacle.reset()
	_obstacle.setup("cone", 200.0, 650.0)
	await get_tree().process_frame

	var sprite: Sprite2D = _obstacle.get_node("Sprite")
	var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
	var shape: RectangleShape2D = collision.shape as RectangleShape2D

	if sprite and sprite.texture and shape:
		var tex_aspect: float = sprite.texture.get_size().x / sprite.texture.get_size().y
		var collision_aspect: float = shape.size.x / shape.size.y
		assert_almost_eq(
			collision_aspect,
			tex_aspect,
			0.1,
			"Cone collision aspect ratio (%.2f) should match texture aspect ratio (%.2f)" % [
				collision_aspect, tex_aspect
			]
		)

# =============================================================================
# DUCK-UNDER OBSTACLE BOUNDARY TESTS
# =============================================================================

func test_duck_under_collision_position_matches_sprite_position():
	# For duck_under obstacles with height_offset, the collision and sprite
	# should have the same position offset
	var duck_types = ["barrier", "beam"]
	for obs_type in duck_types:
		if not _configs.has(obs_type):
			continue
		_obstacle.reset()
		_obstacle.setup(obs_type, 200.0, 650.0)
		await get_tree().process_frame

		var sprite: Sprite2D = _obstacle.get_node("Sprite")
		var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")

		assert_eq(
			collision.position.y,
			sprite.position.y,
			"Duck obstacle '%s' collision Y offset should match sprite Y offset" % obs_type
		)

func test_duck_lane_obstacles_use_centralized_lane_offset():
	var expected_offset: float = POSITIONING_CONFIG.DUCK_OBSTACLE_Y - POSITIONING_CONFIG.GROUND_Y
	for obs_type in _configs:
		var config: Dictionary = _configs[obs_type]
		if config.get("spawn_lane", "") != "duck_lane":
			continue
		_obstacle.reset()
		_obstacle.setup(obs_type, 200.0, POSITIONING_CONFIG.GROUND_Y)
		await get_tree().process_frame

		var sprite: Sprite2D = _obstacle.get_node("Sprite")
		var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
		assert_eq(
			sprite.position.y,
			expected_offset,
			"Duck-lane obstacle '%s' should use centralized duck-lane offset" % obs_type
		)
		assert_eq(
			collision.position.y,
			expected_offset,
			"Duck-lane obstacle '%s' collision should match centralized duck-lane offset" % obs_type
		)
