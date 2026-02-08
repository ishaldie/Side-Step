## Unit Tests for GameCalculations
## Tests all pure calculation functions
extends GutTest

func after_each():
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# DISTANCE & PROGRESS CALCULATION TESTS
# =============================================================================

func test_calculate_progress_normal():
	assert_eq(GameCalculations.calculate_progress(50, 100), 0.5)
	assert_eq(GameCalculations.calculate_progress(0, 100), 0.0)
	assert_eq(GameCalculations.calculate_progress(100, 100), 1.0)

func test_calculate_progress_over_target():
	# Should clamp to 1.0
	assert_eq(GameCalculations.calculate_progress(150, 100), 1.0)
	assert_eq(GameCalculations.calculate_progress(999, 100), 1.0)

func test_calculate_progress_zero_target():
	# Should return 0.0 to avoid division by zero
	assert_eq(GameCalculations.calculate_progress(50, 0), 0.0)
	assert_eq(GameCalculations.calculate_progress(0, 0), 0.0)

func test_calculate_progress_negative_target():
	assert_eq(GameCalculations.calculate_progress(50, -10), 0.0)

func test_is_distance_complete():
	assert_true(GameCalculations.is_distance_complete(100.0, 100.0))
	assert_true(GameCalculations.is_distance_complete(150.0, 100.0))
	assert_false(GameCalculations.is_distance_complete(99.0, 100.0))
	assert_false(GameCalculations.is_distance_complete(0.0, 100.0))

func test_coin_percentage():
	assert_eq(GameCalculations.coin_percentage(5, 10), 0.5)
	assert_eq(GameCalculations.coin_percentage(0, 10), 0.0)
	assert_eq(GameCalculations.coin_percentage(10, 10), 1.0)
	assert_eq(GameCalculations.coin_percentage(5, 0), 0.0)  # Avoid division by zero

func test_calculate_stars():
	# Default thresholds: 70%, 85%, 95%
	assert_eq(GameCalculations.calculate_stars(69, 100), 0)  # Below 70%
	assert_eq(GameCalculations.calculate_stars(70, 100), 1)  # Exactly 70%
	assert_eq(GameCalculations.calculate_stars(84, 100), 1)  # Below 85%
	assert_eq(GameCalculations.calculate_stars(85, 100), 2)  # Exactly 85%
	assert_eq(GameCalculations.calculate_stars(94, 100), 2)  # Below 95%
	assert_eq(GameCalculations.calculate_stars(95, 100), 3)  # Exactly 95%
	assert_eq(GameCalculations.calculate_stars(100, 100), 3)  # 100%
	assert_eq(GameCalculations.calculate_stars(50, 0), 0)    # No coins available

func test_coins_after_death():
	assert_eq(GameCalculations.coins_after_death(100, 0.5), 50)
	assert_eq(GameCalculations.coins_after_death(99, 0.5), 49)
	assert_eq(GameCalculations.coins_after_death(0, 0.5), 0)
	assert_eq(GameCalculations.coins_after_death(100, 1.0), 100)
	assert_eq(GameCalculations.coins_after_death(100, 0.0), 0)

func test_is_distance_complete_boundary():
	# Additional boundary tests for distance completion
	assert_true(GameCalculations.is_distance_complete(100.0, 100.0))  # Exact match
	assert_true(GameCalculations.is_distance_complete(100.1, 100.0))  # Slightly over
	assert_false(GameCalculations.is_distance_complete(99.9, 100.0))  # Slightly under

# =============================================================================
# UNLOCK CALCULATION TESTS
# =============================================================================

func test_is_world_unlocked():
	var requirements = [0, 5, 10, 15, 20]
	
	# World 0 always unlocked (requires 0)
	assert_true(GameCalculations.is_world_unlocked(0, 0, requirements))
	
	# World 1 requires 5 completed
	assert_false(GameCalculations.is_world_unlocked(1, 4, requirements))
	assert_true(GameCalculations.is_world_unlocked(1, 5, requirements))
	assert_true(GameCalculations.is_world_unlocked(1, 10, requirements))
	
	# Invalid index
	assert_false(GameCalculations.is_world_unlocked(-1, 10, requirements))
	assert_false(GameCalculations.is_world_unlocked(99, 10, requirements))

func test_is_level_unlocked():
	var completed = [true, true, false, false, false]
	
	# First level always unlocked
	assert_true(GameCalculations.is_level_unlocked(0, completed))
	
	# Level 1 unlocked (level 0 complete)
	assert_true(GameCalculations.is_level_unlocked(1, completed))
	
	# Level 2 unlocked (level 1 complete)
	assert_true(GameCalculations.is_level_unlocked(2, completed))
	
	# Level 3 locked (level 2 not complete)
	assert_false(GameCalculations.is_level_unlocked(3, completed))
	
	# Invalid indices
	assert_false(GameCalculations.is_level_unlocked(-1, completed))
	assert_false(GameCalculations.is_level_unlocked(99, completed))

func test_is_level_unlocked_empty_array():
	assert_false(GameCalculations.is_level_unlocked(0, []))

func test_count_completed_levels():
	var levels_2d = [
		[true, true, false, false, false],  # 2 complete
		[true, false, false, false, false], # 1 complete
		[false, false, false, false, false], # 0 complete
	]
	assert_eq(GameCalculations.count_completed_levels(levels_2d), 3)

func test_count_completed_levels_all_complete():
	var levels_2d = [
		[true, true, true],
		[true, true, true],
	]
	assert_eq(GameCalculations.count_completed_levels(levels_2d), 6)

func test_count_completed_levels_none_complete():
	var levels_2d = [
		[false, false],
		[false, false],
	]
	assert_eq(GameCalculations.count_completed_levels(levels_2d), 0)

func test_count_completed_levels_empty():
	assert_eq(GameCalculations.count_completed_levels([]), 0)

# =============================================================================
# SHOP CALCULATION TESTS
# =============================================================================

func test_can_afford():
	assert_true(GameCalculations.can_afford(100, 50))
	assert_true(GameCalculations.can_afford(100, 100))
	assert_false(GameCalculations.can_afford(100, 101))
	assert_false(GameCalculations.can_afford(0, 1))
	assert_true(GameCalculations.can_afford(0, 0))

func test_coins_after_purchase():
	assert_eq(GameCalculations.coins_after_purchase(100, 30), 70)
	assert_eq(GameCalculations.coins_after_purchase(100, 100), 0)
	assert_eq(GameCalculations.coins_after_purchase(100, 150), 0)  # Can't go negative

# =============================================================================
# INPUT CALCULATION TESTS
# =============================================================================

func test_can_jump_on_ground():
	assert_true(GameCalculations.can_jump(true, 0.0))
	assert_true(GameCalculations.can_jump(true, 0.1))

func test_can_jump_coyote_time():
	assert_true(GameCalculations.can_jump(false, 0.05))
	assert_true(GameCalculations.can_jump(false, 0.001))

func test_can_jump_neither():
	assert_false(GameCalculations.can_jump(false, 0.0))
	assert_false(GameCalculations.can_jump(false, -0.1))

func test_can_double_jump():
	# Has ability, hasn't used it, in air
	assert_true(GameCalculations.can_double_jump(true, false, false))
	
	# No ability
	assert_false(GameCalculations.can_double_jump(false, false, false))
	
	# Already used
	assert_false(GameCalculations.can_double_jump(true, true, false))
	
	# On ground (should regular jump instead)
	assert_false(GameCalculations.can_double_jump(true, false, true))

func test_update_coyote_timer_on_ground():
	# Should reset to max when on ground
	assert_eq(GameCalculations.update_coyote_timer(0.0, 0.016, true, 0.1), 0.1)
	assert_eq(GameCalculations.update_coyote_timer(0.05, 0.016, true, 0.1), 0.1)

func test_update_coyote_timer_in_air():
	# Should decrease when in air
	var result = GameCalculations.update_coyote_timer(0.1, 0.016, false, 0.1)
	assert_almost_eq(result, 0.084, 0.001)

func test_update_coyote_timer_clamps_to_zero():
	assert_eq(GameCalculations.update_coyote_timer(0.01, 0.1, false, 0.1), 0.0)

func test_update_jump_buffer():
	assert_almost_eq(GameCalculations.update_jump_buffer(0.1, 0.016), 0.084, 0.001)
	assert_eq(GameCalculations.update_jump_buffer(0.01, 0.1), 0.0)

# =============================================================================
# OBSTACLE CALCULATION TESTS
# =============================================================================

func test_is_off_screen():
	# Off left
	assert_true(GameCalculations.is_off_screen(-101.0, 500.0, -100.0, 900.0))
	
	# Off bottom
	assert_true(GameCalculations.is_off_screen(200.0, 901.0, -100.0, 900.0))
	
	# Still on screen
	assert_false(GameCalculations.is_off_screen(200.0, 500.0, -100.0, 900.0))
	
	# Edge cases (exactly at boundary)
	assert_false(GameCalculations.is_off_screen(-100.0, 500.0, -100.0, 900.0))
	assert_false(GameCalculations.is_off_screen(200.0, 900.0, -100.0, 900.0))

# =============================================================================
# VALIDATION TESTS
# =============================================================================

func test_is_valid_index():
	assert_true(GameCalculations.is_valid_index(0, 5))
	assert_true(GameCalculations.is_valid_index(4, 5))
	assert_false(GameCalculations.is_valid_index(-1, 5))
	assert_false(GameCalculations.is_valid_index(5, 5))
	assert_false(GameCalculations.is_valid_index(0, 0))

func test_clamp_index():
	assert_eq(GameCalculations.clamp_index(2, 5), 2)
	assert_eq(GameCalculations.clamp_index(-5, 5), 0)
	assert_eq(GameCalculations.clamp_index(10, 5), 4)
	assert_eq(GameCalculations.clamp_index(0, 0), 0)  # Edge case
