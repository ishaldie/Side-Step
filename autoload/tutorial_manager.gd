## TutorialManager Autoload
## Manages first-time user tutorial and contextual help.
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const SAVE_KEY: String = "tutorial"
const TUTORIAL_VERSION: int = 1

# Tutorial steps
enum TutorialStep {
	NONE,
	WELCOME,
	TAP_TO_JUMP,
	COLLECT_COINS,
	AVOID_OBSTACLES,
	DUCK_TUTORIAL,
	STAR_RATING,
	COMPLETE
}

# =============================================================================
# SIGNALS
# =============================================================================

signal tutorial_step_changed(step: TutorialStep)
signal tutorial_completed
signal show_hint(hint_text: String, duration: float)

# =============================================================================
# STATE
# =============================================================================

var _has_seen_tutorial: bool = false
var _current_step: TutorialStep = TutorialStep.NONE
var _tutorial_active: bool = false
var _hints_shown: Dictionary = {}

# Track what the player has learned
var _learned_jump: bool = false
var _learned_duck: bool = false
var _learned_coins: bool = false
var _learned_dash: bool = false
var _learned_double_jump: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_load_tutorial_state()


# =============================================================================
# PUBLIC API
# =============================================================================

## Returns true if this is the player's first time
func is_first_time() -> bool:
	return not _has_seen_tutorial


## Starts the tutorial sequence
func start_tutorial() -> void:
	if _has_seen_tutorial:
		return
	_tutorial_active = true
	_current_step = TutorialStep.WELCOME
	tutorial_step_changed.emit(_current_step)


## Advances to the next tutorial step
func advance_step() -> void:
	if not _tutorial_active:
		return
	
	var next_step: int = _current_step + 1
	if next_step >= TutorialStep.COMPLETE:
		complete_tutorial()
	else:
		_current_step = next_step as TutorialStep
		tutorial_step_changed.emit(_current_step)


## Completes the tutorial
func complete_tutorial() -> void:
	_tutorial_active = false
	_has_seen_tutorial = true
	_current_step = TutorialStep.COMPLETE
	_save_tutorial_state()
	tutorial_completed.emit()


## Skips the tutorial
func skip_tutorial() -> void:
	complete_tutorial()


## Returns the current tutorial step
func get_current_step() -> TutorialStep:
	return _current_step


## Returns true if tutorial is active
func is_tutorial_active() -> bool:
	return _tutorial_active


## Shows a contextual hint (won't repeat)
func show_contextual_hint(hint_id: String, hint_text: String, duration: float = 3.0) -> void:
	if _hints_shown.get(hint_id, false):
		return
	_hints_shown[hint_id] = true
	show_hint.emit(hint_text, duration)


## Called when player successfully jumps
func on_player_jumped() -> void:
	if not _learned_jump:
		_learned_jump = true
		if _tutorial_active and _current_step == TutorialStep.TAP_TO_JUMP:
			advance_step()


## Called when player collects a coin
func on_coin_collected() -> void:
	if not _learned_coins:
		_learned_coins = true
		if _tutorial_active and _current_step == TutorialStep.COLLECT_COINS:
			advance_step()


## Called when player ducks
func on_player_ducked() -> void:
	if not _learned_duck:
		_learned_duck = true
		if _tutorial_active and _current_step == TutorialStep.DUCK_TUTORIAL:
			advance_step()


## Called when player uses dash
func on_player_dashed() -> void:
	if not _learned_dash:
		_learned_dash = true
		show_contextual_hint("dash_success", "Great dash! 💨", 2.0)


## Called when player double jumps
func on_player_double_jumped() -> void:
	if not _learned_double_jump:
		_learned_double_jump = true
		show_contextual_hint("double_jump_success", "Double jump! 🦘", 2.0)


## Shows hint for new ability unlocked
func show_ability_hint(ability: String) -> void:
	match ability:
		"dash":
			show_contextual_hint("dash_unlock", "Swipe right to DASH! →", 4.0)
		"double_jump":
			show_contextual_hint("double_jump_unlock", "Tap again in air for DOUBLE JUMP! ⬆⬆", 4.0)


## Returns tutorial text for current step
func get_step_text() -> Dictionary:
	match _current_step:
		TutorialStep.WELCOME:
			return {
				"title": "Welcome to Side Step!",
				"body": "Run, jump, and collect coins to progress through 25 exciting levels!",
				"button": "Let's Go!"
			}
		TutorialStep.TAP_TO_JUMP:
			return {
				"title": "Tap to Jump",
				"body": "Tap anywhere on the upper part of the screen to jump over obstacles.",
				"button": "Got it!"
			}
		TutorialStep.COLLECT_COINS:
			return {
				"title": "Collect Coins",
				"body": "Grab coins to earn stars and unlock new shoes in the shop!",
				"button": "Nice!"
			}
		TutorialStep.AVOID_OBSTACLES:
			return {
				"title": "Avoid Obstacles",
				"body": "Don't hit obstacles or you'll lose! Some you jump over, some you duck under.",
				"button": "Okay!"
			}
		TutorialStep.DUCK_TUTORIAL:
			return {
				"title": "Duck to Dodge",
				"body": "Hold the bottom of the screen or swipe down to duck under obstacles.",
				"button": "Ready!"
			}
		TutorialStep.STAR_RATING:
			return {
				"title": "Earn Stars",
				"body": "Collect 70% of coins for ⭐, 85% for ⭐⭐, and 95% for ⭐⭐⭐!",
				"button": "Let's Play!"
			}
		_:
			return {"title": "", "body": "", "button": ""}


## Returns mobile control instructions
func get_control_hints() -> Array[Dictionary]:
	return [
		{"icon": "👆", "action": "TAP", "description": "Jump"},
		{"icon": "👆👆", "action": "DOUBLE TAP", "description": "Double Jump*"},
		{"icon": "👇", "action": "HOLD BOTTOM", "description": "Duck"},
		{"icon": "👉", "action": "SWIPE RIGHT", "description": "Dash*"},
	]


# =============================================================================
# SAVE/LOAD
# =============================================================================

func _save_tutorial_state() -> void:
	var config := ConfigFile.new()
	if config.load(GameManager.SAVE_PATH) != OK:
		config = ConfigFile.new()
	
	config.set_value(SAVE_KEY, "version", TUTORIAL_VERSION)
	config.set_value(SAVE_KEY, "completed", _has_seen_tutorial)
	config.set_value(SAVE_KEY, "learned_jump", _learned_jump)
	config.set_value(SAVE_KEY, "learned_duck", _learned_duck)
	config.set_value(SAVE_KEY, "learned_coins", _learned_coins)
	config.set_value(SAVE_KEY, "learned_dash", _learned_dash)
	config.set_value(SAVE_KEY, "learned_double_jump", _learned_double_jump)
	config.set_value(SAVE_KEY, "hints_shown", _hints_shown)
	config.save(GameManager.SAVE_PATH)


func _load_tutorial_state() -> void:
	var config := ConfigFile.new()
	if config.load(GameManager.SAVE_PATH) != OK:
		return
	
	_has_seen_tutorial = config.get_value(SAVE_KEY, "completed", false)
	_learned_jump = config.get_value(SAVE_KEY, "learned_jump", false)
	_learned_duck = config.get_value(SAVE_KEY, "learned_duck", false)
	_learned_coins = config.get_value(SAVE_KEY, "learned_coins", false)
	_learned_dash = config.get_value(SAVE_KEY, "learned_dash", false)
	_learned_double_jump = config.get_value(SAVE_KEY, "learned_double_jump", false)
	_hints_shown = config.get_value(SAVE_KEY, "hints_shown", {})


## Resets tutorial state (for testing)
func reset_tutorial() -> void:
	_has_seen_tutorial = false
	_learned_jump = false
	_learned_duck = false
	_learned_coins = false
	_learned_dash = false
	_learned_double_jump = false
	_hints_shown = {}
	_current_step = TutorialStep.NONE
	_tutorial_active = false
	_save_tutorial_state()
