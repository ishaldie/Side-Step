## Integration Tests for GameManager
## Tests GameManager state management and persistence
extends GutTest

# =============================================================================
# SETUP / TEARDOWN
# =============================================================================

func before_each():
	# Reset GameManager state before each test
	GameManager.reset_progress()
	# Also reset session state (coins, distance)
	GameManager.coins = 0
	GameManager.distance = 0.0
	GameManager.coins_available = 0

func after_each():
	# Clean up pooled objects to avoid orphans
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# INITIALIZATION TESTS
# =============================================================================

func test_initial_state():
	assert_eq(GameManager.current_shoe, GameManager.ShoeType.BAREFOOT)
	assert_eq(GameManager.current_world_index, 0)
	assert_eq(GameManager.current_level_index, 0)
	assert_eq(GameManager.total_coins, 0)
	assert_eq(GameManager.coins, 0)
	assert_eq(GameManager.distance, 0.0)

func test_initial_unlocked_shoes():
	# First shoe should be unlocked
	assert_true(GameManager.unlocked_shoes[0])
	# Others should be locked
	for i in range(1, GameManager.unlocked_shoes.size()):
		assert_false(GameManager.unlocked_shoes[i], "Shoe %d should start locked" % i)

func test_initial_levels_not_completed():
	for w in range(GameManager.WORLDS_COUNT):
		for l in range(GameManager.LEVELS_PER_WORLD):
			assert_false(
				GameManager.levels_completed[w][l],
				"World %d Level %d should start incomplete" % [w, l]
			)

# =============================================================================
# WORLD/LEVEL ACCESS TESTS
# =============================================================================

func test_get_current_world_data():
	var world = GameManager.get_current_world_data()
	assert_true(world.has("name"))
	assert_true(world.has("levels"))
	assert_eq(world.levels.size(), 5)

func test_get_current_level_data():
	var level = GameManager.get_current_level_data()
	assert_true(level.has("name"))
	assert_true(level.has("target_distance"))
	assert_true(level.has("obstacles"))

func test_get_world_data_bounds():
	# Valid indices
	var world0 = GameManager.get_world_data(0)
	var world4 = GameManager.get_world_data(4)
	assert_true(world0.has("name"))
	assert_true(world4.has("name"))
	
	# Out of bounds should clamp
	var world_neg = GameManager.get_world_data(-1)
	var world_high = GameManager.get_world_data(99)
	assert_eq(world_neg.name, GameManager.get_world_data(0).name)
	assert_eq(world_high.name, GameManager.get_world_data(4).name)

# =============================================================================
# UNLOCK LOGIC TESTS
# =============================================================================

func test_first_world_always_unlocked():
	assert_true(GameManager.is_world_unlocked(0))

func test_second_world_locked_initially():
	assert_false(GameManager.is_world_unlocked(1))

func test_first_level_always_unlocked():
	assert_true(GameManager.is_level_unlocked(0, 0))

func test_second_level_locked_initially():
	assert_false(GameManager.is_level_unlocked(0, 1))

func test_completing_level_unlocks_next():
	# Complete level 0
	GameManager.levels_completed[0][0] = true
	
	# Level 1 should now be unlocked
	assert_true(GameManager.is_level_unlocked(0, 1))

# =============================================================================
# DISTANCE & COIN TESTS
# =============================================================================

func test_add_distance():
	GameManager.add_distance(100.0)
	assert_eq(GameManager.distance, 100.0)

	GameManager.add_distance(50.0)
	assert_eq(GameManager.distance, 150.0)

func test_collect_coin():
	GameManager.collect_coin(1)
	assert_eq(GameManager.coins, 1)

func test_collect_multiple_coins():
	GameManager.collect_coin(1)
	GameManager.collect_coin(1)
	GameManager.collect_coin(1)
	assert_eq(GameManager.coins, 3)

func test_record_coin_spawned():
	GameManager.record_coin_spawned(1)
	GameManager.record_coin_spawned(1)
	assert_eq(GameManager.coins_available, 2)

func test_level_progress():
	# Set up a level with known target_distance
	GameManager.current_world_index = 0
	GameManager.current_level_index = 0
	var level = GameManager.get_current_level_data()
	var target = level.target_distance

	# At 0 distance, progress should be 0
	GameManager.distance = 0.0
	assert_eq(GameManager.get_level_progress(), 0.0)

	# At half distance, progress should be 0.5
	GameManager.distance = target / 2.0
	assert_almost_eq(GameManager.get_level_progress(), 0.5, 0.01)

	# At full distance, progress should be 1.0
	GameManager.distance = target
	assert_eq(GameManager.get_level_progress(), 1.0)

func test_is_level_distance_complete():
	GameManager.current_world_index = 0
	GameManager.current_level_index = 0
	var level = GameManager.get_current_level_data()
	var target = level.target_distance

	GameManager.distance = target - 1.0
	assert_false(GameManager.is_level_distance_complete())

	GameManager.distance = target
	assert_true(GameManager.is_level_distance_complete())

# =============================================================================
# SHOP TESTS
# =============================================================================

func test_can_afford_shoe():
	GameManager.total_coins = 600
	
	# Barefoot is free
	assert_true(GameManager.can_afford_shoe(0))
	
	# Flip flops cost 500
	assert_true(GameManager.can_afford_shoe(1))
	
	# Running shoes cost 1500
	assert_false(GameManager.can_afford_shoe(2))

func test_purchase_shoe():
	GameManager.total_coins = 600
	
	# Purchase flip flops (cost 500)
	var success = GameManager.purchase_shoe(1)
	
	assert_true(success)
	assert_eq(GameManager.total_coins, 100)
	assert_true(GameManager.unlocked_shoes[1])

func test_purchase_shoe_insufficient_funds():
	GameManager.total_coins = 100
	
	var success = GameManager.purchase_shoe(1)  # Costs 500
	
	assert_false(success)
	assert_eq(GameManager.total_coins, 100)  # Unchanged
	assert_false(GameManager.unlocked_shoes[1])  # Still locked

func test_purchase_already_owned():
	GameManager.total_coins = 100
	GameManager.unlocked_shoes[1] = true  # Already own it
	
	var success = GameManager.purchase_shoe(1)
	
	assert_false(success)
	assert_eq(GameManager.total_coins, 100)  # No charge

func test_equip_shoe():
	GameManager.unlocked_shoes[1] = true
	
	GameManager.equip_shoe(1)
	
	assert_eq(GameManager.current_shoe, 1)

func test_equip_locked_shoe_fails():
	GameManager.unlocked_shoes[2] = false
	
	GameManager.equip_shoe(2)
	
	assert_ne(GameManager.current_shoe, 2)  # Should not equip

# =============================================================================
# PROGRESS TESTS
# =============================================================================

func test_get_total_levels_completed():
	assert_eq(GameManager.get_total_levels_completed(), 0)
	
	GameManager.levels_completed[0][0] = true
	GameManager.levels_completed[0][1] = true
	GameManager.levels_completed[1][0] = true
	
	assert_eq(GameManager.get_total_levels_completed(), 3)

func test_get_world_progress():
	assert_eq(GameManager.get_world_progress(0), 0)
	
	GameManager.levels_completed[0][0] = true
	GameManager.levels_completed[0][2] = true
	
	assert_eq(GameManager.get_world_progress(0), 2)

# =============================================================================
# RESET TESTS
# =============================================================================

func test_reset_progress():
	# Set up some progress
	GameManager.total_coins = 500
	GameManager.current_shoe = 2
	GameManager.unlocked_shoes[2] = true
	GameManager.levels_completed[0][0] = true
	
	# Reset
	GameManager.reset_progress()
	
	# Verify reset
	assert_eq(GameManager.total_coins, 0)
	assert_eq(GameManager.current_shoe, 0)
	assert_false(GameManager.unlocked_shoes[2])
	assert_false(GameManager.levels_completed[0][0])
