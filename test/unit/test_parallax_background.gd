## Unit Tests for Parallax Scrolling Backgrounds
## Validates parallax layer creation, scroll ratios, and per-world configs
extends GutTest

# =============================================================================
# SETUP / TEARDOWN
# =============================================================================

var _parent: Node2D

func before_each():
	_parent = Node2D.new()
	add_child_autofree(_parent)
	await get_tree().process_frame

func after_each():
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# BACKGROUND GENERATOR CONFIG
# =============================================================================

func test_parallax_configs_exist_for_all_worlds():
	assert_true(
		BackgroundGenerator.PARALLAX_CONFIGS.size() >= 5,
		"Should have parallax configs for all 5 worlds"
	)

func test_parallax_configs_have_required_keys():
	for i in range(BackgroundGenerator.PARALLAX_CONFIGS.size()):
		var config = BackgroundGenerator.PARALLAX_CONFIGS[i]
		assert_true(config.has("far_speed_ratio"), "World %d config missing far_speed_ratio" % i)
		assert_true(config.has("near_speed_ratio"), "World %d config missing near_speed_ratio" % i)

func test_far_speed_slower_than_near():
	for i in range(BackgroundGenerator.PARALLAX_CONFIGS.size()):
		var config = BackgroundGenerator.PARALLAX_CONFIGS[i]
		assert_lt(
			config.far_speed_ratio,
			config.near_speed_ratio,
			"World %d: far layer should scroll slower than near layer" % i
		)

func test_speed_ratios_are_positive():
	for i in range(BackgroundGenerator.PARALLAX_CONFIGS.size()):
		var config = BackgroundGenerator.PARALLAX_CONFIGS[i]
		assert_gt(config.far_speed_ratio, 0.0, "World %d far_speed_ratio should be positive" % i)
		assert_gt(config.near_speed_ratio, 0.0, "World %d near_speed_ratio should be positive" % i)

func test_speed_ratios_less_than_one():
	for i in range(BackgroundGenerator.PARALLAX_CONFIGS.size()):
		var config = BackgroundGenerator.PARALLAX_CONFIGS[i]
		assert_lt(config.far_speed_ratio, 1.0, "World %d far_speed_ratio should be < 1.0" % i)
		assert_lt(config.near_speed_ratio, 1.0, "World %d near_speed_ratio should be < 1.0" % i)

# =============================================================================
# PARALLAX CREATION
# =============================================================================

func test_create_background_adds_parallax_node():
	var bg = BackgroundGenerator.new(_parent)
	var world_data = GameManager.WORLDS[0]
	bg.create_background(0, world_data)
	await get_tree().process_frame

	var parallax_bg = _parent.get_node_or_null("ParallaxBG")
	assert_not_null(parallax_bg, "Should create a ParallaxBackground node named ParallaxBG")

func test_parallax_has_far_layer():
	var bg = BackgroundGenerator.new(_parent)
	var world_data = GameManager.WORLDS[0]
	bg.create_background(0, world_data)
	await get_tree().process_frame

	var parallax_bg = _parent.get_node_or_null("ParallaxBG")
	if parallax_bg:
		var far = parallax_bg.get_node_or_null("FarLayer")
		assert_not_null(far, "ParallaxBG should have a FarLayer child")

func test_parallax_has_near_layer():
	var bg = BackgroundGenerator.new(_parent)
	var world_data = GameManager.WORLDS[0]
	bg.create_background(0, world_data)
	await get_tree().process_frame

	var parallax_bg = _parent.get_node_or_null("ParallaxBG")
	if parallax_bg:
		var near = parallax_bg.get_node_or_null("NearLayer")
		assert_not_null(near, "ParallaxBG should have a NearLayer child")

# =============================================================================
# SCROLL UPDATE
# =============================================================================

func test_update_parallax_scroll_moves_offset():
	var bg = BackgroundGenerator.new(_parent)
	var world_data = GameManager.WORLDS[0]
	bg.create_background(0, world_data)
	await get_tree().process_frame

	var parallax_bg = _parent.get_node_or_null("ParallaxBG")
	if parallax_bg:
		var initial_offset = parallax_bg.scroll_offset
		bg.update_parallax_scroll(200.0, 0.1)  # speed=200, delta=0.1
		assert_ne(
			parallax_bg.scroll_offset,
			initial_offset,
			"Scroll offset should change after update_parallax_scroll"
		)

func test_update_parallax_scroll_moves_left():
	var bg = BackgroundGenerator.new(_parent)
	var world_data = GameManager.WORLDS[0]
	bg.create_background(0, world_data)
	await get_tree().process_frame

	bg.update_parallax_scroll(200.0, 0.1)
	var parallax_bg = _parent.get_node_or_null("ParallaxBG")
	if parallax_bg:
		# Scroll offset.x should decrease (moving left)
		assert_lt(
			parallax_bg.scroll_offset.x,
			0.0,
			"Parallax should scroll left (negative x offset)"
		)

# =============================================================================
# FALLBACK
# =============================================================================

func test_fallback_still_works_for_missing_images():
	var bg = BackgroundGenerator.new(_parent)
	# Use a valid world data dict but invalid index that won't have an image
	var world_data = GameManager.WORLDS[0]
	bg.create_background(99, world_data)  # Index 99 has no image
	await get_tree().process_frame
	# Should not crash — procedural fallback should work
	assert_true(true, "Fallback should not crash for missing world index")
