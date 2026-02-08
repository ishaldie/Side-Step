## Level Complete Screen
## Shown after successfully completing a level.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _level_name_label: Label = $Panel/VBoxContainer/LevelNameLabel
@onready var _stars_label: Label = $Panel/VBoxContainer/StarsLabel
@onready var _coins_label: Label = $Panel/VBoxContainer/CoinsLabel
@onready var _total_coins_label: Label = $Panel/VBoxContainer/TotalCoinsLabel
@onready var _background: ColorRect = $Background

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	var world_data: Dictionary = GameManager.get_current_world_data()
	var level_data: Dictionary = GameManager.get_current_level_data()
	
	_level_name_label.text = "%s %s Complete!" % [world_data.icon, level_data.name]
	
	# Calculate and display stars
	var coin_percentage: float = 0.0
	if GameManager.coins_available > 0:
		coin_percentage = float(GameManager.coins) / float(GameManager.coins_available)
	var stars: int = GameManager.calculate_stars(coin_percentage)
	
	# Display stars with Kenney star textures
	_stars_label.text = ""  # Clear text, we'll use texture children
	_create_star_display(stars)

	# Show coin collection info
	var percentage_text: String = "%d%%" % int(coin_percentage * 100)
	_coins_label.text = "Coins: %d/%d (%s)" % [GameManager.coins, GameManager.coins_available, percentage_text]
	_total_coins_label.text = "Total:  %d" % GameManager.total_coins
	UIUtils.add_coin_icon(_total_coins_label, Vector2(18, 18), Vector2(42, 2))
	_background.color = world_data.bg_color.darkened(0.4)


## Creates star icons using Kenney textures.
func _create_star_display(earned_stars: int) -> void:
	# Remove existing star icons
	for child in _stars_label.get_children():
		child.queue_free()

	var star_container := HBoxContainer.new()
	star_container.alignment = BoxContainer.ALIGNMENT_CENTER
	star_container.position = Vector2(0, 0)

	for i in range(3):
		var star_icon := TextureRect.new()
		if i < earned_stars:
			star_icon.texture = load(UIUtils.STAR_ICON_PATH)
		else:
			star_icon.texture = load(UIUtils.STAR_EMPTY_ICON_PATH)
		star_icon.custom_minimum_size = Vector2(36, 36)
		star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star_container.add_child(star_icon)

	_stars_label.add_child(star_container)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_next_button_pressed()

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_next_button_pressed() -> void:
	AudioManager.play_button()
	var world_idx: int = GameManager.current_world_index
	var level_idx: int = GameManager.current_level_index
	
	if level_idx + 1 < GameManager.LEVELS_PER_WORLD:
		GameManager.start_level(world_idx, level_idx + 1)
	elif world_idx + 1 < GameManager.WORLDS_COUNT:
		if GameManager.is_world_unlocked(world_idx + 1):
			GameManager.start_level(world_idx + 1, 0)
		else:
			GameManager.go_to_world_select()
	else:
		GameManager.go_to_victory()


func _on_replay_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.restart_level()


func _on_menu_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_level_select(GameManager.current_world_index)


func _on_shop_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_shop()
