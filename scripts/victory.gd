## Victory Screen
## Shown when the player completes all levels.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _total_coins_label: Label = $Panel/VBoxContainer/TotalCoinsLabel
@onready var _levels_label: Label = $Panel/VBoxContainer/LevelsLabel
@onready var _shoes_label: Label = $Panel/VBoxContainer/ShoesLabel
@onready var _bonus_label: Label = $Panel/VBoxContainer/BonusLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_total_coins_label.text = "Total Coins:  %d" % GameManager.total_coins
	UIUtils.add_coin_icon(_total_coins_label, Vector2(18, 18), Vector2(95, 2))
	
	var completed: int = GameManager.get_total_levels_completed()
	_levels_label.text = "Levels: %d / %d" % [completed, GameManager.TOTAL_LEVELS]
	
	var unlocked_count: int = _count_unlocked_shoes()
	_shoes_label.text = "Shoes: %d / %d" % [unlocked_count, GameManager.SHOES.size()]
	
	var is_100_percent: bool = completed >= GameManager.TOTAL_LEVELS and unlocked_count >= GameManager.SHOES.size()
	if is_100_percent:
		_bonus_label.text = "🏆 100% COMPLETE! 🏆"
		_bonus_label.show()
	else:
		_bonus_label.hide()


func _count_unlocked_shoes() -> int:
	var count: int = 0
	for is_unlocked in GameManager.unlocked_shoes:
		if is_unlocked:
			count += 1
	return count

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_play_again_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_world_select()


func _on_shop_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_shop()


func _on_menu_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_main_menu()
