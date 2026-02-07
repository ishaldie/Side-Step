## Unit Tests for Game Data Configurations
## Validates worlds, levels, and shoe configs
extends GutTest

func after_all():
	# Clean up any pooled objects
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# SHOE CONFIG TESTS
# =============================================================================

func test_shoes_array_exists():
	assert_eq(GameManager.SHOES.size(), 4, "Should have 4 shoes")

func test_all_shoes_have_required_fields():
	var required = ["type", "name", "icon", "description", "cost", "speed", "jump_force", "dash", "double_jump"]
	
	for i in range(GameManager.SHOES.size()):
		var shoe = GameManager.SHOES[i]
		for field in required:
			assert_true(
				shoe.has(field),
				"Shoe %d missing field '%s'" % [i, field]
			)

func test_first_shoe_is_free():
	assert_eq(GameManager.SHOES[0].cost, 0, "First shoe (barefoot) should be free")

func test_shoe_costs_increase():
	for i in range(1, GameManager.SHOES.size()):
		assert_gt(
			GameManager.SHOES[i].cost,
			GameManager.SHOES[i-1].cost,
			"Shoe %d should cost more than shoe %d" % [i, i-1]
		)

func test_shoe_stats_are_positive():
	for i in range(GameManager.SHOES.size()):
		var shoe = GameManager.SHOES[i]
		assert_gt(shoe.speed, 0, "Shoe %d speed should be positive" % i)
		assert_gt(shoe.jump_force, 0, "Shoe %d jump_force should be positive" % i)

func test_shoe_abilities_are_boolean():
	for i in range(GameManager.SHOES.size()):
		var shoe = GameManager.SHOES[i]
		assert_typeof(shoe.dash, TYPE_BOOL, "Shoe %d dash should be bool" % i)
		assert_typeof(shoe.double_jump, TYPE_BOOL, "Shoe %d double_jump should be bool" % i)

# =============================================================================
# WORLD CONFIG TESTS
# =============================================================================

func test_worlds_array_exists():
	assert_eq(GameManager.WORLDS.size(), 5, "Should have 5 worlds")

func test_all_worlds_have_required_fields():
	var required = ["name", "icon", "description", "bg_color", "ground_color", "unlock_requirement", "levels"]
	
	for i in range(GameManager.WORLDS.size()):
		var world = GameManager.WORLDS[i]
		for field in required:
			assert_true(
				world.has(field),
				"World %d missing field '%s'" % [i, field]
			)

func test_first_world_unlocked_by_default():
	assert_eq(
		GameManager.WORLDS[0].unlock_requirement, 
		0, 
		"First world should require 0 levels to unlock"
	)

func test_world_unlock_requirements_increase():
	for i in range(1, GameManager.WORLDS.size()):
		assert_gt(
			GameManager.WORLDS[i].unlock_requirement,
			GameManager.WORLDS[i-1].unlock_requirement,
			"World %d should require more levels than world %d" % [i, i-1]
		)

func test_each_world_has_5_levels():
	for i in range(GameManager.WORLDS.size()):
		assert_eq(
			GameManager.WORLDS[i].levels.size(),
			5,
			"World %d should have 5 levels" % i
		)

func test_world_colors_are_valid():
	for i in range(GameManager.WORLDS.size()):
		var world = GameManager.WORLDS[i]
		assert_true(world.bg_color is Color, "World %d bg_color should be Color" % i)
		assert_true(world.ground_color is Color, "World %d ground_color should be Color" % i)

# =============================================================================
# LEVEL CONFIG TESTS
# =============================================================================

func test_all_levels_have_required_fields():
	var required = ["name", "description", "obstacles", "obstacle_speed", "spawn_interval", "target_distance", "coin_chance", "difficulty"]

	for w in range(GameManager.WORLDS.size()):
		for l in range(GameManager.WORLDS[w].levels.size()):
			var level = GameManager.WORLDS[w].levels[l]
			for field in required:
				assert_true(
					level.has(field),
					"World %d Level %d missing field '%s'" % [w, l, field]
				)

func test_level_obstacles_not_empty():
	for w in range(GameManager.WORLDS.size()):
		for l in range(GameManager.WORLDS[w].levels.size()):
			var level = GameManager.WORLDS[w].levels[l]
			assert_gt(
				level.obstacles.size(),
				0,
				"World %d Level %d should have at least one obstacle type" % [w, l]
			)

func test_level_target_distances_positive():
	for w in range(GameManager.WORLDS.size()):
		for l in range(GameManager.WORLDS[w].levels.size()):
			var level = GameManager.WORLDS[w].levels[l]
			assert_gt(
				level.target_distance,
				0,
				"World %d Level %d target_distance should be positive" % [w, l]
			)

func test_level_spawn_intervals_valid():
	for w in range(GameManager.WORLDS.size()):
		for l in range(GameManager.WORLDS[w].levels.size()):
			var level = GameManager.WORLDS[w].levels[l]
			assert_gt(level.spawn_interval, 0.0, "Spawn interval should be positive")
			assert_lt(level.spawn_interval, 10.0, "Spawn interval should be reasonable")

func test_level_coin_chance_valid():
	for w in range(GameManager.WORLDS.size()):
		for l in range(GameManager.WORLDS[w].levels.size()):
			var level = GameManager.WORLDS[w].levels[l]
			assert_gte(level.coin_chance, 0.0, "Coin chance should be >= 0")
			assert_lte(level.coin_chance, 1.0, "Coin chance should be <= 1")

func test_level_difficulty_increases_within_world():
	for w in range(GameManager.WORLDS.size()):
		for l in range(1, GameManager.WORLDS[w].levels.size()):
			var prev_level = GameManager.WORLDS[w].levels[l-1]
			var curr_level = GameManager.WORLDS[w].levels[l]
			assert_gte(
				curr_level.difficulty,
				prev_level.difficulty,
				"World %d Level %d difficulty should be >= Level %d" % [w, l, l-1]
			)

# =============================================================================
# CROSS-REFERENCE TESTS
# =============================================================================

func test_level_obstacles_exist_in_configs():
	var obstacle_script = load("res://scripts/obstacle.gd")
	var valid_obstacles = obstacle_script.CONFIGS.keys()
	
	for w in range(GameManager.WORLDS.size()):
		for l in range(GameManager.WORLDS[w].levels.size()):
			var level = GameManager.WORLDS[w].levels[l]
			for obs in level.obstacles:
				assert_has(
					valid_obstacles,
					obs,
					"World %d Level %d uses undefined obstacle '%s'" % [w, l, obs]
				)

func test_total_levels_constant_correct():
	var actual_total = GameManager.WORLDS.size() * 5
	assert_eq(
		GameManager.TOTAL_LEVELS,
		actual_total,
		"TOTAL_LEVELS constant should match actual level count"
	)
