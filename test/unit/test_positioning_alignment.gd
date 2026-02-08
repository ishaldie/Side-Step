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
