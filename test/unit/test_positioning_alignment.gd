## Unit Tests for positioning alignment assumptions
extends GutTest

func test_player_and_game_ground_constants_match():
	var player_script = load("res://scripts/player.gd")
	var game_script = load("res://scripts/game.gd")
	assert_eq(
		player_script.GROUND_Y,
		game_script.GROUND_LEVEL_Y,
		"Player GROUND_Y should match game GROUND_LEVEL_Y"
	)

func test_duck_lane_is_above_ground_lane():
	var game_script = load("res://scripts/game.gd")
	assert_lt(
		game_script.DUCK_OBSTACLE_Y,
		game_script.GROUND_LEVEL_Y,
		"Duck obstacle lane should be above ground lane"
	)

func test_positioning_constants_are_centralized():
	var positioning_script = load("res://scripts/positioning_config.gd")
	var game_script = load("res://scripts/game.gd")
	var player_script = load("res://scripts/player.gd")

	assert_eq(player_script.GROUND_Y, positioning_script.GROUND_Y)
	assert_eq(game_script.GROUND_LEVEL_Y, positioning_script.GROUND_Y)
	assert_eq(game_script.GROUND_Y, positioning_script.GROUND_Y)
	assert_eq(game_script.DUCK_OBSTACLE_Y, positioning_script.DUCK_OBSTACLE_Y)
	assert_eq(game_script.FLYING_OBSTACLE_Y_MIN, positioning_script.FLYING_OBSTACLE_Y_MIN)
	assert_eq(game_script.FLYING_OBSTACLE_Y_MAX, positioning_script.FLYING_OBSTACLE_Y_MAX)
