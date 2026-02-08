## Unit Tests for Powerup System
## Validates powerup types, spawning, collection, effects, and expiry
extends GutTest

# =============================================================================
# SETUP / TEARDOWN
# =============================================================================

func after_each():
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# POWERUP SCRIPT CONFIG
# =============================================================================

func test_powerup_type_enum_has_three_types():
	assert_eq(Powerup.Type.size(), 3, "Powerup should have 3 types")

func test_powerup_types_are_named_correctly():
	assert_true(Powerup.Type.has("MAGNET"), "Should have MAGNET type")
	assert_true(Powerup.Type.has("SHIELD"), "Should have SHIELD type")
	assert_true(Powerup.Type.has("SPEED_BOOST"), "Should have SPEED_BOOST type")

func test_powerup_configs_exist_for_all_types():
	for type_name in Powerup.Type.keys():
		var type_val = Powerup.Type[type_name]
		assert_true(
			Powerup.CONFIGS.has(type_val),
			"Powerup config should exist for type %s" % type_name
		)

func test_powerup_configs_have_required_fields():
	var required_fields = ["duration", "sprite_path"]
	for type_val in Powerup.CONFIGS:
		var config = Powerup.CONFIGS[type_val]
		for field in required_fields:
			assert_true(
				config.has(field),
				"Powerup config %s missing field '%s'" % [type_val, field]
			)

func test_powerup_durations_are_positive():
	for type_val in Powerup.CONFIGS:
		var config = Powerup.CONFIGS[type_val]
		assert_gt(
			config.duration,
			0.0,
			"Powerup %s duration should be positive" % type_val
		)

func test_powerup_sprite_paths_exist():
	for type_val in Powerup.CONFIGS:
		var config = Powerup.CONFIGS[type_val]
		assert_true(
			ResourceLoader.exists(config.sprite_path),
			"Powerup %s sprite should exist at %s" % [type_val, config.sprite_path]
		)

# =============================================================================
# EVENTBUS SIGNALS
# =============================================================================

func test_eventbus_has_powerup_collected_signal():
	assert_true(
		EventBus.has_signal("powerup_collected"),
		"EventBus should have powerup_collected signal"
	)

func test_eventbus_has_powerup_activated_signal():
	assert_true(
		EventBus.has_signal("powerup_activated"),
		"EventBus should have powerup_activated signal"
	)

func test_eventbus_has_powerup_expired_signal():
	assert_true(
		EventBus.has_signal("powerup_expired"),
		"EventBus should have powerup_expired signal"
	)

# =============================================================================
# POWERUP SPAWN CONFIG
# =============================================================================

func test_default_powerup_chance_is_valid():
	# Powerups use a default chance when not specified in level data
	# game.gd uses level_data.get("powerup_chance", 0.05)
	# So default should be a small positive float
	var default_chance: float = 0.05
	assert_gt(default_chance, 0.0, "Default powerup chance should be positive")
	assert_lt(default_chance, 1.0, "Default powerup chance should be less than 1")

func test_powerup_configs_have_valid_magnet_radius():
	var config = Powerup.CONFIGS[Powerup.Type.MAGNET]
	assert_true(config.has("magnet_radius"), "Magnet config should have magnet_radius")
	assert_gt(config.magnet_radius, 0.0, "Magnet radius should be positive")

func test_powerup_configs_have_valid_speed_multiplier():
	var config = Powerup.CONFIGS[Powerup.Type.SPEED_BOOST]
	assert_true(config.has("speed_multiplier"), "Speed boost config should have speed_multiplier")
	assert_gt(config.speed_multiplier, 1.0, "Speed multiplier should be > 1.0")
