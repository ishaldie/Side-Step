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

func test_all_configs_have_avoidance_classification():
	var valid_avoidance = ["jump", "duck"]
	for obs_type in _configs:
		var config = _configs[obs_type]
		assert_true(config.has("avoidance"), "Obstacle '%s' missing 'avoidance' classification" % obs_type)
		if config.has("avoidance"):
			assert_has(
				valid_avoidance,
				config.avoidance,
				"Obstacle '%s' has invalid avoidance '%s'" % [obs_type, str(config.avoidance)]
			)

func test_all_configs_have_spawn_lane():
	var valid_spawn_lanes = ["ground", "duck_lane", "flying_lane"]
	for obs_type in _configs:
		var config = _configs[obs_type]
		assert_true(config.has("spawn_lane"), "Obstacle '%s' missing 'spawn_lane'" % obs_type)
		if config.has("spawn_lane"):
			assert_has(
				valid_spawn_lanes,
				config.spawn_lane,
				"Obstacle '%s' has invalid spawn_lane '%s'" % [obs_type, str(config.spawn_lane)]
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
		# Every obstacle must explicitly specify ground
		assert_true(
			has_ground,
			"Obstacle '%s' must have 'ground' field" % obs_type
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

func test_duck_classified_obstacles_are_duck_under():
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("avoidance", "") == "duck":
			assert_true(
				config.get("duck_under", false),
				"Duck obstacle '%s' should set duck_under=true" % obs_type
			)

func test_jump_classified_obstacles_not_duck_under():
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("avoidance", "") == "jump":
			assert_false(
				config.get("duck_under", false),
				"Jump obstacle '%s' should not set duck_under=true" % obs_type
			)

# =============================================================================
# FLOOR / PLAYER ALIGNMENT TESTS
# =============================================================================

func test_player_ground_y_matches_game_ground_level_y():
	# Player GROUND_Y and Game GROUND_LEVEL_Y must agree
	var player_script = load("res://scripts/player.gd")
	var game_script = load("res://scripts/game.gd")
	assert_eq(
		player_script.GROUND_Y,
		game_script.GROUND_LEVEL_Y,
		"Player GROUND_Y (%s) must match Game GROUND_LEVEL_Y (%s)" % [
			player_script.GROUND_Y, game_script.GROUND_LEVEL_Y
		]
	)

func test_game_ground_y_matches_ground_level_y():
	# Game has both GROUND_Y and GROUND_LEVEL_Y — they must be equal
	var game_script = load("res://scripts/game.gd")
	assert_eq(
		game_script.GROUND_Y,
		game_script.GROUND_LEVEL_Y,
		"Game GROUND_Y (%s) must match GROUND_LEVEL_Y (%s)" % [
			game_script.GROUND_Y, game_script.GROUND_LEVEL_Y
		]
	)

func test_duck_obstacle_y_above_ground():
	# DUCK_OBSTACLE_Y must be above GROUND_LEVEL_Y (lower Y = higher on screen)
	var game_script = load("res://scripts/game.gd")
	assert_lt(
		game_script.DUCK_OBSTACLE_Y,
		game_script.GROUND_LEVEL_Y,
		"DUCK_OBSTACLE_Y (%s) must be above GROUND_LEVEL_Y (%s)" % [
			game_script.DUCK_OBSTACLE_Y, game_script.GROUND_LEVEL_Y
		]
	)

func test_flying_obstacle_range_above_duck_range():
	# Flying obstacles should generally be at or above duck height
	var game_script = load("res://scripts/game.gd")
	assert_true(
		game_script.FLYING_OBSTACLE_Y_MAX <= game_script.DUCK_OBSTACLE_Y,
		"FLYING_OBSTACLE_Y_MAX (%s) should be at or above DUCK_OBSTACLE_Y (%s)" % [
			game_script.FLYING_OBSTACLE_Y_MAX, game_script.DUCK_OBSTACLE_Y
		]
	)

func test_flying_obstacle_y_range_valid():
	var game_script = load("res://scripts/game.gd")
	assert_lt(
		game_script.FLYING_OBSTACLE_Y_MIN,
		game_script.FLYING_OBSTACLE_Y_MAX,
		"FLYING_OBSTACLE_Y_MIN should be less than FLYING_OBSTACLE_Y_MAX"
	)

# =============================================================================
# SPAWN LANE CONSISTENCY TESTS
# =============================================================================

func test_ground_obstacles_spawn_at_ground():
	# Ground obstacles (avoidance=jump, ground=true) must use spawn_lane=ground
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("ground", false) and not config.get("flying", false) and not config.get("duck_under", false):
			assert_eq(
				config.get("spawn_lane", ""),
				"ground",
				"Ground obstacle '%s' should have spawn_lane=ground" % obs_type
			)

func test_flying_duck_obstacles_spawn_at_flying_lane():
	# Flying duck_under obstacles must use spawn_lane=flying_lane
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("flying", false) and config.get("duck_under", false):
			assert_eq(
				config.get("spawn_lane", ""),
				"flying_lane",
				"Flying duck obstacle '%s' should have spawn_lane=flying_lane" % obs_type
			)

func test_non_flying_duck_obstacles_spawn_at_duck_lane():
	# Non-flying duck_under obstacles (barrier, beam) must use spawn_lane=duck_lane
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("duck_under", false) and not config.get("flying", false):
			assert_eq(
				config.get("spawn_lane", ""),
				"duck_lane",
				"Non-flying duck obstacle '%s' should have spawn_lane=duck_lane" % obs_type
			)

func test_obstacle_height_offset_only_on_duck_lane():
	# height_offset should only exist on duck_lane obstacles
	for obs_type in _configs:
		var config = _configs[obs_type]
		if config.get("height_offset", 0.0) != 0.0:
			assert_eq(
				config.get("spawn_lane", ""),
				"duck_lane",
				"Obstacle '%s' with height_offset should be spawn_lane=duck_lane" % obs_type
			)
