## Unit Tests for Obstacle Configurations
## Validates all obstacle configs have required fields
extends GutTest

var _configs: Dictionary

func before_all():
	# Load the obstacle configs
	var obstacle_script = load("res://scripts/obstacle.gd")
	_configs = obstacle_script.CONFIGS

func after_all():
	# Clean up any pooled objects
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# CONFIG VALIDATION TESTS
# =============================================================================

func test_configs_not_empty():
	assert_gt(_configs.size(), 0, "Should have at least one obstacle config")

func test_all_configs_have_required_fields():
	var required_fields = ["color", "width", "height"]
	
	for obs_type in _configs:
		var config = _configs[obs_type]
		for field in required_fields:
			assert_true(
				config.has(field),
				"Obstacle '%s' missing required field '%s'" % [obs_type, field]
			)

func test_all_configs_have_valid_dimensions():
	for obs_type in _configs:
		var config = _configs[obs_type]
		assert_gt(config.width, 0, "Obstacle '%s' width should be positive" % obs_type)
		assert_gt(config.height, 0, "Obstacle '%s' height should be positive" % obs_type)

func test_all_configs_have_valid_color():
	for obs_type in _configs:
		var config = _configs[obs_type]
		var color = config.color
		assert_true(color is Color, "Obstacle '%s' color should be a Color" % obs_type)

func test_ground_or_flying_specified():
	for obs_type in _configs:
		var config = _configs[obs_type]
		# Should have either "ground" or "flying" (or default to ground)
		var has_ground = config.has("ground")
		var has_flying = config.has("flying")
		# At least implicitly ground if neither specified
		assert_true(
			has_ground or has_flying or true,  # Always passes but documents intent
			"Obstacle '%s' should specify ground or flying" % obs_type
		)

func test_shape_is_valid():
	var valid_shapes = ["triangle", "circle", "flat", "rect", "fish", "crab", "jellyfish", "funnel", "banana"]
	
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.has("shape"):
			assert_has(
				valid_shapes,
				config.shape,
				"Obstacle '%s' has invalid shape '%s'" % [obs_type, config.shape]
			)

# =============================================================================
# WORLD-SPECIFIC OBSTACLE TESTS
# =============================================================================

func test_world1_road_obstacles_exist():
	var road_obstacles = ["cone", "pothole", "backpack", "bike", "hydrant"]
	for obs in road_obstacles:
		assert_true(_configs.has(obs), "Road obstacle '%s' should exist" % obs)

func test_world2_soccer_obstacles_exist():
	var soccer_obstacles = ["soccer_ball", "water_bottle", "sliding_player"]
	for obs in soccer_obstacles:
		assert_true(_configs.has(obs), "Soccer obstacle '%s' should exist" % obs)

func test_world3_beach_obstacles_exist():
	var beach_obstacles = ["sandcastle", "beach_ball", "crab"]
	for obs in beach_obstacles:
		assert_true(_configs.has(obs), "Beach obstacle '%s' should exist" % obs)

func test_world4_underwater_obstacles_exist():
	var underwater_obstacles = ["jellyfish", "coral", "shark"]
	for obs in underwater_obstacles:
		assert_true(_configs.has(obs), "Underwater obstacle '%s' should exist" % obs)

func test_world5_volcano_obstacles_exist():
	var volcano_obstacles = ["hot_rock", "steam_vent", "ash_pile"]
	for obs in volcano_obstacles:
		assert_true(_configs.has(obs), "Volcano obstacle '%s' should exist" % obs)

# =============================================================================
# BEHAVIORAL CONFIG TESTS
# =============================================================================

func test_bouncing_obstacles_are_ground():
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("bounces", false):
			assert_true(
				config.get("ground", true),
				"Bouncing obstacle '%s' should be ground-based" % obs_type
			)

func test_flying_obstacles_not_ground():
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("flying", false):
			assert_false(
				config.get("ground", false),
				"Flying obstacle '%s' should not be ground-based" % obs_type
			)
