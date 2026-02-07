## ObjectPool Autoload
## Manages pools of reusable game objects to reduce allocation/deallocation overhead.
## Usage: ObjectPool.get_obstacle() / ObjectPool.release_obstacle(obj)
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when pool warm-up is complete
signal pools_ready

# =============================================================================
# CONSTANTS
# =============================================================================

const OBSTACLE_SCENE_PATH: String = "res://scenes/obstacle.tscn"
const COIN_SCENE_PATH: String = "res://scenes/coin.tscn"

const INITIAL_OBSTACLE_POOL_SIZE: int = 20
const INITIAL_COIN_POOL_SIZE: int = 30
const MAX_POOL_SIZE: int = 50
const WARMUP_BATCH_SIZE: int = 5  # Objects to create per frame during warm-up

# =============================================================================
# POOL STORAGE
# =============================================================================

var _obstacle_pool: Array[Area2D] = []
var _coin_pool: Array[Area2D] = []

var _obstacle_scene: PackedScene = null
var _coin_scene: PackedScene = null

# Use Dictionary for O(1) lookup instead of Array linear search
var _active_obstacles: Dictionary = {}  # {object_id: Area2D}
var _active_coins: Dictionary = {}  # {object_id: Area2D}

var _is_initialized: bool = false
var _is_warming_up: bool = false

# =============================================================================
# STATISTICS (for debugging)
# =============================================================================

var stats: Dictionary = {
	"obstacles_created": 0,
	"obstacles_reused": 0,
	"coins_created": 0,
	"coins_reused": 0
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_load_scenes()
	if _is_initialized:
		_prewarm_pools_async()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_cleanup_all()


## Safely loads scene resources with error handling.
func _load_scenes() -> void:
	# Check if resources exist before loading
	if not ResourceLoader.exists(OBSTACLE_SCENE_PATH):
		push_error("[ObjectPool] Obstacle scene not found: " + OBSTACLE_SCENE_PATH)
		return
	
	if not ResourceLoader.exists(COIN_SCENE_PATH):
		push_error("[ObjectPool] Coin scene not found: " + COIN_SCENE_PATH)
		return
	
	_obstacle_scene = load(OBSTACLE_SCENE_PATH)
	_coin_scene = load(COIN_SCENE_PATH)
	
	if not _obstacle_scene:
		push_error("[ObjectPool] Failed to load obstacle scene")
		return
	
	if not _coin_scene:
		push_error("[ObjectPool] Failed to load coin scene")
		return
	
	_is_initialized = true


## Returns whether the pool is ready to use.
func is_ready() -> bool:
	return _is_initialized and not _is_warming_up


## Pre-instantiate objects asynchronously to avoid startup stutter.
func _prewarm_pools_async() -> void:
	if _is_warming_up:
		return
	
	_is_warming_up = true
	
	# Warm up obstacles in batches
	var obstacles_created: int = 0
	while obstacles_created < INITIAL_OBSTACLE_POOL_SIZE:
		var batch_count: int = mini(WARMUP_BATCH_SIZE, INITIAL_OBSTACLE_POOL_SIZE - obstacles_created)
		for i in range(batch_count):
			var obstacle := _create_obstacle()
			if obstacle:
				_obstacle_pool.append(obstacle)
				obstacles_created += 1
		await get_tree().process_frame
	
	# Warm up coins in batches
	var coins_created: int = 0
	while coins_created < INITIAL_COIN_POOL_SIZE:
		var batch_count: int = mini(WARMUP_BATCH_SIZE, INITIAL_COIN_POOL_SIZE - coins_created)
		for i in range(batch_count):
			var coin := _create_coin()
			if coin:
				_coin_pool.append(coin)
				coins_created += 1
		await get_tree().process_frame
	
	_is_warming_up = false
	pools_ready.emit()
	print("[ObjectPool] Warm-up complete: %d obstacles, %d coins" % [obstacles_created, coins_created])

# =============================================================================
# OBSTACLE POOL
# =============================================================================

## Get an obstacle from the pool (or create new if empty).
## Returns null if pool is not initialized.
func get_obstacle() -> Area2D:
	if not _is_initialized:
		push_error("[ObjectPool] Cannot get obstacle - pool not initialized")
		return null
	
	var obstacle: Area2D = null
	
	if _obstacle_pool.size() > 0:
		obstacle = _obstacle_pool.pop_back()
		stats.obstacles_reused += 1
	else:
		obstacle = _create_obstacle()
		if obstacle:
			stats.obstacles_created += 1
	
	if not obstacle:
		push_error("[ObjectPool] Failed to get obstacle from pool")
		return null

	# Use object instance ID for O(1) dictionary lookup
	_active_obstacles[obstacle.get_instance_id()] = obstacle
	obstacle.set_process(true)
	obstacle.set_physics_process(true)
	obstacle.visible = true
	obstacle.monitoring = true
	obstacle.monitorable = true

	return obstacle


## Return an obstacle to the pool for reuse
func release_obstacle(obstacle: Area2D) -> void:
	if obstacle == null:
		return

	# O(1) dictionary removal instead of O(n) array search
	var obj_id: int = obstacle.get_instance_id()
	if _active_obstacles.has(obj_id):
		_active_obstacles.erase(obj_id)
	
	# Don't exceed max pool size
	if _obstacle_pool.size() >= MAX_POOL_SIZE:
		obstacle.queue_free()
		return
	
	_reset_obstacle(obstacle)
	_obstacle_pool.append(obstacle)


func _create_obstacle() -> Area2D:
	if not _obstacle_scene:
		push_error("[ObjectPool] Cannot create obstacle - scene not loaded")
		return null
	var obstacle: Area2D = _obstacle_scene.instantiate()
	if not obstacle:
		push_error("[ObjectPool] Failed to instantiate obstacle")
		return null
	obstacle.set_process(false)
	obstacle.set_physics_process(false)
	obstacle.visible = false
	return obstacle


func _reset_obstacle(obstacle: Area2D) -> void:
	obstacle.set_process(false)
	obstacle.set_physics_process(false)
	obstacle.visible = false
	obstacle.monitoring = false
	obstacle.monitorable = false
	obstacle.position = Vector2(-1000, -1000)

	# Call obstacle's own reset method (uses cached @onready sprite reference)
	if obstacle.has_method("reset"):
		obstacle.reset()

	# Remove from parent if attached
	if obstacle.get_parent():
		obstacle.get_parent().remove_child(obstacle)

# =============================================================================
# COIN POOL
# =============================================================================

## Get a coin from the pool (or create new if empty).
## Returns null if pool is not initialized.
func get_coin() -> Area2D:
	if not _is_initialized:
		push_error("[ObjectPool] Cannot get coin - pool not initialized")
		return null
	
	var coin: Area2D = null
	
	if _coin_pool.size() > 0:
		coin = _coin_pool.pop_back()
		stats.coins_reused += 1
	else:
		coin = _create_coin()
		if coin:
			stats.coins_created += 1
	
	if not coin:
		push_error("[ObjectPool] Failed to get coin from pool")
		return null

	# Use object instance ID for O(1) dictionary lookup
	_active_coins[coin.get_instance_id()] = coin
	coin.set_process(true)
	coin.set_physics_process(true)
	coin.visible = true
	coin.monitoring = true
	coin.monitorable = true

	return coin


## Return a coin to the pool for reuse
func release_coin(coin: Area2D) -> void:
	if coin == null:
		return

	# O(1) dictionary removal instead of O(n) array search
	var obj_id: int = coin.get_instance_id()
	if _active_coins.has(obj_id):
		_active_coins.erase(obj_id)
	
	if _coin_pool.size() >= MAX_POOL_SIZE:
		coin.queue_free()
		return
	
	_reset_coin(coin)
	_coin_pool.append(coin)


func _create_coin() -> Area2D:
	if not _coin_scene:
		push_error("[ObjectPool] Cannot create coin - scene not loaded")
		return null
	var coin: Area2D = _coin_scene.instantiate()
	if not coin:
		push_error("[ObjectPool] Failed to instantiate coin")
		return null
	coin.set_process(false)
	coin.set_physics_process(false)
	coin.visible = false
	return coin


func _reset_coin(coin: Area2D) -> void:
	coin.set_process(false)
	coin.set_physics_process(false)
	coin.visible = false
	coin.monitoring = false
	coin.monitorable = false
	coin.position = Vector2(-1000, -1000)

	# Call coin's own reset method (uses cached @onready sprite reference)
	if coin.has_method("reset"):
		coin.reset()

	if coin.get_parent():
		coin.get_parent().remove_child(coin)

# =============================================================================
# CLEANUP
# =============================================================================

## Release all active objects back to pools (call on level end/restart)
func release_all() -> void:
	# Iterate over dictionary values
	for obstacle in _active_obstacles.values():
		_reset_obstacle(obstacle)
		if _obstacle_pool.size() < MAX_POOL_SIZE:
			_obstacle_pool.append(obstacle)
		else:
			obstacle.queue_free()

	for coin in _active_coins.values():
		_reset_coin(coin)
		if _coin_pool.size() < MAX_POOL_SIZE:
			_coin_pool.append(coin)
		else:
			coin.queue_free()

	_active_obstacles.clear()
	_active_coins.clear()


## Completely clear all pools and free all objects (for testing/cleanup)
func clear_pools() -> void:
	release_all()
	
	# Free all pooled obstacles
	for obstacle in _obstacle_pool:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	_obstacle_pool.clear()
	
	# Free all pooled coins
	for coin in _coin_pool:
		if is_instance_valid(coin):
			coin.queue_free()
	_coin_pool.clear()
	
	# Reset stats
	stats = {
		"obstacles_created": 0,
		"obstacles_reused": 0,
		"coins_created": 0,
		"coins_reused": 0
	}


## Get pool statistics for debugging
func get_stats() -> Dictionary:
	return {
		"obstacle_pool_size": _obstacle_pool.size(),
		"coin_pool_size": _coin_pool.size(),
		"active_obstacles": _active_obstacles.size(),  # Dictionary.size() works the same
		"active_coins": _active_coins.size(),
		"total_obstacles_created": stats.obstacles_created,
		"total_obstacles_reused": stats.obstacles_reused,
		"total_coins_created": stats.coins_created,
		"total_coins_reused": stats.coins_reused
	}


## Clean up all objects on exit to prevent memory leaks
func _cleanup_all() -> void:
	# Free all active obstacles (iterate dictionary values)
	for obstacle in _active_obstacles.values():
		if is_instance_valid(obstacle):
			if obstacle.get_parent():
				obstacle.get_parent().remove_child(obstacle)
			obstacle.free()
	_active_obstacles.clear()

	# Free all active coins (iterate dictionary values)
	for coin in _active_coins.values():
		if is_instance_valid(coin):
			if coin.get_parent():
				coin.get_parent().remove_child(coin)
			coin.free()
	_active_coins.clear()

	# Free all pooled obstacles
	for obstacle in _obstacle_pool:
		if is_instance_valid(obstacle):
			obstacle.free()
	_obstacle_pool.clear()

	# Free all pooled coins
	for coin in _coin_pool:
		if is_instance_valid(coin):
			coin.free()
	_coin_pool.clear()
