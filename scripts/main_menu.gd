## Main Menu Screen
## Entry point for the game, shows progress and navigation options.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _shoe_label: Label = $VBoxContainer/ShoeLabel
@onready var _coins_label: Label = $VBoxContainer/CoinsLabel
@onready var _progress_label: Label = $VBoxContainer/ProgressLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_update_display()


func _update_display() -> void:
	var shoe_data: Dictionary = GameManager.get_current_shoe_data()
	_shoe_label.text = "Gear: %s %s" % [shoe_data.icon, shoe_data.name]
	_coins_label.text = " %d" % GameManager.total_coins
	UIUtils.add_coin_icon(_coins_label)

	var completed: int = GameManager.get_total_levels_completed()
	_progress_label.text = "%d / %d levels completed" % [completed, GameManager.TOTAL_LEVELS]

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_play_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_world_select()


func _on_shop_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_shop()


func _on_settings_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_settings()


func _on_how_to_play_pressed() -> void:
	AudioManager.play_button()
	# Reset tutorial so it shows again
	TutorialManager.reset_tutorial()
	# Go to first level to show tutorial
	GameManager.start_level(0, 0)


func _on_quit_button_pressed() -> void:
	AudioManager.play_button()
	get_tree().quit()


func _on_reset_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.reset_progress()
	_update_display()
