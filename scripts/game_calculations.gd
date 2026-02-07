## GameCalculations
## Pure static functions for game logic calculations.
## These have no side effects and are easily unit testable.
class_name GameCalculations
extends RefCounted

# =============================================================================
# DISTANCE/PROGRESS CALCULATIONS
# =============================================================================

## Calculates level progress as a percentage (0.0 to 1.0)
static func calculate_progress(current: float, target: float) -> float:
	if target <= 0:
		return 0.0
	return clampf(current / target, 0.0, 1.0)


## Checks if level distance target is reached
static func is_distance_complete(current_distance: float, target_distance: float) -> bool:
	return current_distance >= target_distance


## Calculates coins kept after death (penalty applied)
static func coins_after_death(coins: int, penalty: float = 0.5) -> int:
	return int(coins * penalty)

# =============================================================================
# STAR CALCULATIONS
# =============================================================================

## Calculates stars earned based on coin collection percentage
static func calculate_stars(coins_collected: int, coins_available: int, 
		threshold_1: float = 0.70, threshold_2: float = 0.85, threshold_3: float = 0.95) -> int:
	if coins_available <= 0:
		return 0
	var percentage: float = float(coins_collected) / float(coins_available)
	if percentage >= threshold_3:
		return 3
	elif percentage >= threshold_2:
		return 2
	elif percentage >= threshold_1:
		return 1
	else:
		return 0


## Calculates coin collection percentage
static func coin_percentage(coins_collected: int, coins_available: int) -> float:
	if coins_available <= 0:
		return 0.0
	return float(coins_collected) / float(coins_available)


## Counts total stars across all worlds
static func count_total_stars(level_stars_2d: Array) -> int:
	var total: int = 0
	for world_stars in level_stars_2d:
		for stars in world_stars:
			total += stars
	return total


## Checks if world is unlocked based on total stars
static func is_world_unlocked_by_stars(world_index: int, total_stars: int, stars_per_unlock: int) -> bool:
	if world_index <= 0:
		return true
	var required: int = world_index * stars_per_unlock
	return total_stars >= required

# =============================================================================
# UNLOCK CALCULATIONS
# =============================================================================

## Checks if a world should be unlocked based on total completed levels
static func is_world_unlocked(world_index: int, total_completed: int, requirements: Array) -> bool:
	if world_index < 0 or world_index >= requirements.size():
		return false
	return total_completed >= requirements[world_index]


## Checks if a level is unlocked (first level always unlocked, others need previous complete)
static func is_level_unlocked(level_index: int, levels_completed: Array) -> bool:
	if level_index < 0 or level_index >= levels_completed.size():
		return false
	if level_index == 0:
		return true
	return levels_completed[level_index - 1]


## Counts total completed levels across all worlds
static func count_completed_levels(levels_completed_2d: Array) -> int:
	var total: int = 0
	for world_levels in levels_completed_2d:
		for completed in world_levels:
			if completed:
				total += 1
	return total

# =============================================================================
# SHOP CALCULATIONS
# =============================================================================

## Checks if player can afford a shoe
static func can_afford(total_coins: int, shoe_cost: int) -> bool:
	return total_coins >= shoe_cost


## Calculates remaining coins after purchase
static func coins_after_purchase(total_coins: int, cost: int) -> int:
	return maxi(total_coins - cost, 0)

# =============================================================================
# INPUT CALCULATIONS
# =============================================================================

## Checks if jump should be allowed (on ground or within coyote time)
static func can_jump(is_on_ground: bool, coyote_timer: float) -> bool:
	return is_on_ground or coyote_timer > 0.0


## Checks if double jump is available
static func can_double_jump(has_ability: bool, already_used: bool, is_on_ground: bool) -> bool:
	return has_ability and not already_used and not is_on_ground


## Updates coyote timer value
static func update_coyote_timer(current: float, delta: float, is_on_ground: bool, max_time: float) -> float:
	if is_on_ground:
		return max_time
	return maxf(current - delta, 0.0)


## Updates jump buffer timer
static func update_jump_buffer(current: float, delta: float) -> float:
	return maxf(current - delta, 0.0)

# =============================================================================
# OBSTACLE CALCULATIONS  
# =============================================================================

## Checks if obstacle is off screen and should be recycled
static func is_off_screen(pos_x: float, pos_y: float, left_bound: float, bottom_bound: float) -> bool:
	return pos_x < left_bound or pos_y > bottom_bound


## Determines Y position for obstacle spawn based on type
static func get_spawn_y(is_flying: bool, ground_y: float, fly_min: float, fly_max: float) -> float:
	if is_flying:
		return randf_range(fly_min, fly_max)
	return ground_y

# =============================================================================
# VALIDATION
# =============================================================================

## Validates array index is in bounds
static func is_valid_index(index: int, array_size: int) -> bool:
	return index >= 0 and index < array_size


## Clamps an index to valid range
static func clamp_index(index: int, array_size: int) -> int:
	if array_size <= 0:
		return 0
	return clampi(index, 0, array_size - 1)
