## Unit Tests for Obstacle Boundary/Collision Alignment
## Validates that collision shapes match rendered sprite bounds
extends GutTest

const OBSTACLE_SCENE = preload("res://scenes/obstacle.tscn")
const POSITIONING_CONFIG = preload("res://scripts/positioning_config.gd")
const COLLISION_SIZE_RATIO: float = 1.0
# Tolerance for floating point comparison (pixels)
const TOLERANCE: float = 2.0

var _configs: Dictionary
var _obstacle: Area2D

func _get_rendered_visual_size(sprite: Sprite2D) -> Vector2:
	if not sprite or not sprite.texture:
		return Vector2.ZERO
	var image: Image = sprite.texture.get_image()
	if image:
		var used: Rect2i = image.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			return Vector2(used.size) * sprite.scale.abs()
	return sprite.texture.get_size() * sprite.scale.abs()

func _get_expected_collision_offset(sprite: Sprite2D) -> Vector2:
	if not sprite or not sprite.texture:
		return Vector2.ZERO
	var tex_size: Vector2 = sprite.texture.get_size()
	var image: Image = sprite.texture.get_image()
	if not image:
		return sprite.position
	var used: Rect2i = image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return sprite.position
	var texture_center: Vector2 = tex_size * 0.5
	var visual_center: Vector2 = Vector2(used.position) + (Vector2(used.size) * 0.5)
	return sprite.position + (visual_center - texture_center) * sprite.scale

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

		var rendered_width: float = _get_rendered_visual_size(sprite).x
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

		var rendered_height: float = _get_rendered_visual_size(sprite).y
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

		var visual_size: Vector2 = _get_rendered_visual_size(sprite)
		var rendered_w: float = visual_size.x
		var rendered_h: float = visual_size.y
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
		var visual_size: Vector2 = _get_rendered_visual_size(sprite)
		var rendered_w: float = visual_size.x
		var rendered_h: float = visual_size.y
		assert_almost_eq(
			shape.size.x,
			rendered_w * COLLISION_SIZE_RATIO,
			TOLERANCE,
			"Tire collision width should match rendered_width"
		)
		assert_almost_eq(
			shape.size.y,
			rendered_h * COLLISION_SIZE_RATIO,
			TOLERANCE,
			"Tire collision height should match rendered_height"
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
		var visual_size: Vector2 = _get_rendered_visual_size(sprite)
		if visual_size.y <= 0.0:
			return
		var tex_aspect: float = visual_size.x / visual_size.y
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

func test_duck_under_collision_position_matches_visual_center():
	# Collision center offset should follow the visible sprite center, not raw texture center.
	var duck_types = ["barrier", "beam"]
	for obs_type in duck_types:
		if not _configs.has(obs_type):
			continue
		_obstacle.reset()
		_obstacle.setup(obs_type, 200.0, 650.0)
		await get_tree().process_frame

		var sprite: Sprite2D = _obstacle.get_node("Sprite")
		var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")

		var expected_offset: Vector2 = _get_expected_collision_offset(sprite)
		assert_almost_eq(
			collision.position.y,
			expected_offset.y,
			TOLERANCE,
			"Duck obstacle '%s' collision Y offset should match visual center offset" % obs_type
		)

func test_duck_lane_obstacles_use_centralized_lane_offset():
	var expected_bottom: float = POSITIONING_CONFIG.DUCK_OBSTACLE_CLEAR_BOTTOM_Y
	for obs_type in _configs:
		var config: Dictionary = _configs[obs_type]
		if config.get("spawn_lane", "") != "duck_lane":
			continue
		_obstacle.reset()
		_obstacle.setup(obs_type, 200.0, POSITIONING_CONFIG.GROUND_Y)
		await get_tree().process_frame

		var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
		var shape: RectangleShape2D = collision.shape as RectangleShape2D
		if not shape:
			continue
		var collision_bottom: float = _obstacle.position.y + collision.position.y + (shape.size.y * 0.5)
		assert_almost_eq(
			collision_bottom,
			expected_bottom,
			0.05,
			"Duck-lane obstacle '%s' collision bottom should use centralized duck-lane clearance" % obs_type
		)
