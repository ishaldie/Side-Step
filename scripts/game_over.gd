## Game Over Screen
## Shown when the player dies, displays score and helpful tips.
extends Control

# =============================================================================
# CONSTANTS
# =============================================================================

const TIPS: Array[String] = [
	"Tip: Jump over obstacles!",
	"Tip: Collect coins to buy better shoes!",
	"Tip: Running Shoes give you a dash ability!",
	"Tip: Winged Shoes let you double jump!",
	"Tip: Watch for flying obstacles!",
	"Tip: The Shop has powerful upgrades!",
	"Tip: Flip Flops make you faster!",
	"Tip: Keep trying - you've got this!"
]

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var _coins_label: Label = $Panel/VBoxContainer/CoinsLabel
@onready var _tip_label: Label = $Panel/VBoxContainer/TipLabel
@onready var _background: ColorRect = $Background

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	var distance_meters: int = int(GameManager.distance / 100.0)
	_score_label.text = "Distance: %dm" % distance_meters
	_coins_label.text = "Coins: +%d (half on death)" % (GameManager.coins / 2)
	_tip_label.text = TIPS[randi() % TIPS.size()]
	
	var world_data: Dictionary = GameManager.get_current_world_data()
	_background.color = world_data.bg_color.darkened(0.5)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_retry_button_pressed()

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_retry_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.restart_level()


func _on_shop_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_shop()


func _on_menu_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_level_select(GameManager.current_world_index)
