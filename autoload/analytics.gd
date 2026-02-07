## Analytics Autoload
## Provides a framework for tracking game events and player behavior.
## Currently logs events locally; can be extended to integrate with
## Firebase Analytics, GameAnalytics, or other services.
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when any event is logged. External services can connect to this.
signal event_logged(event_name: String, params: Dictionary)

# =============================================================================
# CONSTANTS
# =============================================================================

const MAX_EVENT_HISTORY: int = 100
const LOG_TO_CONSOLE: bool = true  # Set to false in production
const CRASH_LOG_PATH: String = "user://crash_log.txt"
const MAX_CRASH_LOG_ENTRIES: int = 50

# Event names as constants to prevent typos
const EVENT_GAME_START: String = "game_start"
const EVENT_LEVEL_START: String = "level_start"
const EVENT_LEVEL_COMPLETE: String = "level_complete"
const EVENT_LEVEL_FAIL: String = "level_fail"
const EVENT_SHOE_PURCHASED: String = "shoe_purchased"
const EVENT_SHOE_EQUIPPED: String = "shoe_equipped"
const EVENT_TUTORIAL_COMPLETE: String = "tutorial_complete"
const EVENT_SESSION_START: String = "session_start"
const EVENT_SESSION_END: String = "session_end"

# =============================================================================
# STATE
# =============================================================================

var _session_id: String = ""
var _session_start_time: float = 0.0
var _event_history: Array[Dictionary] = []
var _is_initialized: bool = false

# Session stats
var _levels_played: int = 0
var _levels_completed: int = 0
var _coins_collected: int = 0
var _deaths: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_initialize()


func _initialize() -> void:
	_session_id = _generate_session_id()
	_session_start_time = Time.get_unix_time_from_system()
	_is_initialized = true
	
	log_event(EVENT_SESSION_START, {
		"session_id": _session_id
	})
	
	# Connect to game events
	if GameManager:
		GameManager.level_completed.connect(_on_level_completed)
		GameManager.shoe_purchased.connect(_on_shoe_purchased)
		GameManager.shoe_equipped.connect(_on_shoe_equipped)
	
	print("[Analytics] Initialized with session: %s" % _session_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_session_end()

# =============================================================================
# PUBLIC API
# =============================================================================

## Logs an event with optional parameters.
func log_event(event_name: String, params: Dictionary = {}) -> void:
	if not _is_initialized:
		push_warning("[Analytics] Not initialized, event dropped: " + event_name)
		return
	
	# Add standard fields
	params["timestamp"] = Time.get_unix_time_from_system()
	params["session_id"] = _session_id
	params["session_duration"] = Time.get_unix_time_from_system() - _session_start_time
	
	# Store in history
	var event := {
		"name": event_name,
		"params": params
	}
	_event_history.append(event)
	
	# Trim history if too large
	while _event_history.size() > MAX_EVENT_HISTORY:
		_event_history.pop_front()
	
	# Emit signal for external listeners
	event_logged.emit(event_name, params)
	
	# Debug logging
	if LOG_TO_CONSOLE and OS.is_debug_build():
		print("[Analytics] %s: %s" % [event_name, params])


## Logs when a level starts.
func log_level_start(world_index: int, level_index: int) -> void:
	_levels_played += 1
	log_event(EVENT_LEVEL_START, {
		"world_index": world_index,
		"level_index": level_index,
		"shoe_type": GameManager.current_shoe,
		"total_coins": GameManager.total_coins
	})


## Logs when a level is completed.
func log_level_complete(world_index: int, level_index: int, score: int, coins: int) -> void:
	_levels_completed += 1
	_coins_collected += coins
	log_event(EVENT_LEVEL_COMPLETE, {
		"world_index": world_index,
		"level_index": level_index,
		"score": score,
		"coins_earned": coins,
		"total_levels_completed": _levels_completed
	})


## Logs when player dies.
func log_level_fail(world_index: int, level_index: int, score: int, coins: int) -> void:
	_deaths += 1
	log_event(EVENT_LEVEL_FAIL, {
		"world_index": world_index,
		"level_index": level_index,
		"score": score,
		"coins_earned": coins,
		"total_deaths": _deaths
	})


## Logs when a shoe is purchased.
func log_shoe_purchased(shoe_type: int, cost: int) -> void:
	log_event(EVENT_SHOE_PURCHASED, {
		"shoe_type": shoe_type,
		"cost": cost,
		"remaining_coins": GameManager.total_coins
	})


## Logs when a shoe is equipped.
func log_shoe_equipped(shoe_type: int) -> void:
	log_event(EVENT_SHOE_EQUIPPED, {
		"shoe_type": shoe_type
	})

# =============================================================================
# SESSION MANAGEMENT
# =============================================================================

## Returns current session statistics.
func get_session_stats() -> Dictionary:
	return {
		"session_id": _session_id,
		"duration": Time.get_unix_time_from_system() - _session_start_time,
		"levels_played": _levels_played,
		"levels_completed": _levels_completed,
		"coins_collected": _coins_collected,
		"deaths": _deaths,
		"completion_rate": float(_levels_completed) / maxf(_levels_played, 1)
	}


## Returns the event history.
func get_event_history() -> Array[Dictionary]:
	return _event_history.duplicate()


func _on_session_end() -> void:
	var stats := get_session_stats()
	log_event(EVENT_SESSION_END, stats)


func _generate_session_id() -> String:
	var time := Time.get_unix_time_from_system()
	var random := randi()
	return "%d_%d" % [int(time), random]

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_level_completed(world_index: int, level_index: int) -> void:
	log_level_complete(world_index, level_index, GameManager.distance, GameManager.coins)


func _on_shoe_purchased(shoe_type: int) -> void:
	var cost: int = GameManager.SHOES[shoe_type].cost
	log_shoe_purchased(shoe_type, cost)


func _on_shoe_equipped(shoe_type: int) -> void:
	log_shoe_equipped(shoe_type)

# =============================================================================
# CRASH REPORTING
# =============================================================================

## Writes an error entry to the local crash log file.
func log_crash(error_msg: String, context: Dictionary = {}) -> void:
	var timestamp: String = Time.get_datetime_string_from_system()
	var entry: String = "[%s] %s | version=%s | session=%s" % [
		timestamp, error_msg, GameManager.GAME_VERSION, _session_id
	]
	if not context.is_empty():
		entry += " | context=%s" % str(context)
	entry += "\n"

	var file := FileAccess.open(CRASH_LOG_PATH, FileAccess.READ_WRITE)
	if not file:
		# File doesn't exist yet, create it
		file = FileAccess.open(CRASH_LOG_PATH, FileAccess.WRITE)
	if file:
		file.seek_end(0)
		file.store_string(entry)
		file.close()

	# Also log as an analytics event
	log_event("crash", {"error": error_msg, "context": context})


## Returns the contents of the crash log for debugging.
func get_crash_log() -> String:
	if not FileAccess.file_exists(CRASH_LOG_PATH):
		return ""
	var file := FileAccess.open(CRASH_LOG_PATH, FileAccess.READ)
	if not file:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content


## Clears the crash log.
func clear_crash_log() -> void:
	if FileAccess.file_exists(CRASH_LOG_PATH):
		var file := FileAccess.open(CRASH_LOG_PATH, FileAccess.WRITE)
		if file:
			file.store_string("")
			file.close()
