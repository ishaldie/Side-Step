## Unit tests for obstacle avoidance intent vs collision geometry.
extends GutTest

const OBSTACLE_SCENE = preload("res://scenes/obstacle.tscn")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const GAME_SCRIPT = preload("res://scripts/game.gd")

const PLAYER_STAND_HEIGHT: float = PLAYER_SCRIPT.NORMAL_COLLISION_HEIGHT
const PLAYER_DUCK_HEIGHT: float = PLAYER_SCRIPT.NORMAL_COLLISION_HEIGHT * PLAYER_SCRIPT.DUCK_HEIGHT_SCALE
const PLAYER_DUCK_CENTER_OFFSET: float = PLAYER_SCRIPT.DUCK_COLLISION_OFFSET

var _configs: Dictionary
var _obstacle: Area2D

func before_all():
	var obstacle_script = load("res://scripts/obstacle.gd")
	_configs = obstacle_script.CONFIGS

func before_each():
	_obstacle = OBSTACLE_SCENE.instantiate()
	add_child_autofree(_obstacle)
	await get_tree().process_frame

func after_each():
	if ObjectPool:
		ObjectPool.clear_pools()

func _overlap(a_top: float, a_bottom: float, b_top: float, b_bottom: float) -> bool:
	return a_bottom > b_top and a_top < b_bottom

func _spawn_y_for_config(config: Dictionary) -> float:
	var obs_height: float = config.get("height", 40.0)
	var avoidance: String = config.get("avoidance", "jump")
	if avoidance == "duck":
		return GAME_SCRIPT.DUCK_OBSTACLE_CLEAR_BOTTOM_Y - (obs_height / 2.0)
	if config.get("flying", false):
		return GAME_SCRIPT.FLYING_OBSTACLE_Y_MAX
	return GAME_SCRIPT.GROUND_LEVEL_Y - (obs_height / 2.0) + GAME_SCRIPT.GROUND_OBSTACLE_CONTACT_PADDING_Y

func _get_obstacle_bounds(obs_type: String, config: Dictionary) -> Vector2:
	var spawn_y: float = _spawn_y_for_config(config)
	_obstacle.reset()
	_obstacle.position.x = 0.0
	_obstacle.setup(obs_type, 0.0, spawn_y)
	await get_tree().process_frame

	var collision: CollisionShape2D = _obstacle.get_node("CollisionShape2D")
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	if not shape:
		return Vector2.ZERO

	var center_y: float = _obstacle.position.y + collision.position.y
	var half_h: float = shape.size.y * 0.5
	return Vector2(center_y - half_h, center_y + half_h)  # top, bottom

func test_obstacle_profiles_match_avoidance_intent():
	var max_jump_force: float = GameManager.SHOES[GameManager.ShoeType.WINGED_SHOES].jump_force
	var jump_height: float = (max_jump_force * max_jump_force) / (2.0 * PLAYER_SCRIPT.GRAVITY)
	var jump_center_y: float = PLAYER_SCRIPT.GROUND_Y - jump_height

	var stand_top: float = PLAYER_SCRIPT.GROUND_Y - (PLAYER_STAND_HEIGHT * 0.5)
	var stand_bottom: float = PLAYER_SCRIPT.GROUND_Y + (PLAYER_STAND_HEIGHT * 0.5)

	var duck_center_y: float = PLAYER_SCRIPT.GROUND_Y + PLAYER_DUCK_CENTER_OFFSET
	var duck_top: float = duck_center_y - (PLAYER_DUCK_HEIGHT * 0.5)
	var duck_bottom: float = duck_center_y + (PLAYER_DUCK_HEIGHT * 0.5)

	var jump_top: float = jump_center_y - (PLAYER_STAND_HEIGHT * 0.5)
	var jump_bottom: float = jump_center_y + (PLAYER_STAND_HEIGHT * 0.5)

	for obs_type in _configs:
		var config: Dictionary = _configs[obs_type]
		if config.get("projectile", false):
			continue

		var bounds: Vector2 = await _get_obstacle_bounds(obs_type, config)
		var obs_top: float = bounds.x
		var obs_bottom: float = bounds.y

		var hits_standing: bool = _overlap(obs_top, obs_bottom, stand_top, stand_bottom)
		var hits_ducking: bool = _overlap(obs_top, obs_bottom, duck_top, duck_bottom)
		var hits_jump_apex: bool = _overlap(obs_top, obs_bottom, jump_top, jump_bottom)

		var avoidance: String = config.get("avoidance", "jump")
		if avoidance == "duck":
			assert_true(
				hits_standing,
				"Duck obstacle '%s' should threaten standing player (obs: %.1f-%.1f, stand: %.1f-%.1f)" % [
					obs_type, obs_top, obs_bottom, stand_top, stand_bottom
				]
			)
			assert_false(
				hits_ducking,
				"Duck obstacle '%s' should be avoidable by ducking (obs: %.1f-%.1f, duck: %.1f-%.1f)" % [
					obs_type, obs_top, obs_bottom, duck_top, duck_bottom
				]
			)
		else:
			assert_true(
				hits_standing,
				"Jump obstacle '%s' should threaten standing player (obs: %.1f-%.1f, stand: %.1f-%.1f)" % [
					obs_type, obs_top, obs_bottom, stand_top, stand_bottom
				]
			)
			assert_false(
				hits_jump_apex,
				"Jump obstacle '%s' should be clearable with max jump (obs: %.1f-%.1f, jump: %.1f-%.1f)" % [
					obs_type, obs_top, obs_bottom, jump_top, jump_bottom
				]
			)
