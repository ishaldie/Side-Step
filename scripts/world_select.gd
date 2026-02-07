## World Selection Screen
## Displays all worlds with their unlock status and progress.
extends Control

# =============================================================================
# CONSTANTS
# =============================================================================

const CARD_SIZE: Vector2 = Vector2(420, 120)
const CARD_SPACING: float = 12.0
const CARD_CORNER_RADIUS: int = 12

const WORLD_COLORS: Array[Color] = [
	Color(0.3, 0.32, 0.38),   # Road - gray
	Color(0.2, 0.4, 0.25),    # Soccer - green
	Color(0.3, 0.5, 0.6),     # Beach - cyan
	Color(0.15, 0.25, 0.4),   # Underwater - blue
	Color(0.4, 0.2, 0.15)     # Volcano - red
]

const LOCKED_COLOR: Color = Color(0.15, 0.15, 0.18)
const STAR_COLOR: Color = Color(1, 0.85, 0)
const STAR_LOCKED_COLOR: Color = Color(0.4, 0.4, 0.4)

const WORLD_ICON_PATHS: Array[String] = [
	"res://assets/sprites/worlds/world_road.png",
	"res://assets/sprites/worlds/world_soccer.png",
	"res://assets/sprites/worlds/world_beach.png",
	"res://assets/sprites/worlds/world_underwater.png",
	"res://assets/sprites/worlds/world_volcano.png"
]
const WORLD_ICON_SIZE: Vector2 = Vector2(80, 80)

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _worlds_container: VBoxContainer = $ScrollContainer/WorldsContainer
@onready var _coins_label: Label = $CoinsLabel
@onready var _progress_label: Label = $ProgressLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_coins_label.text = " %d" % GameManager.total_coins
	UIUtils.add_coin_icon(_coins_label, Vector2(18, 18), Vector2(-20, 2))
	var total_stars: int = GameManager.get_total_stars()
	var max_stars: int = GameManager.TOTAL_LEVELS * 3
	_progress_label.text = " %d / %d" % [total_stars, max_stars]
	UIUtils.add_star_icon(_progress_label)
	_create_world_buttons()


func _create_world_buttons() -> void:
	for child in _worlds_container.get_children():
		child.queue_free()
	
	for i in range(GameManager.WORLDS_COUNT):
		_create_world_card(i)


func _create_world_card(world_index: int) -> void:
	var world_data: Dictionary = GameManager.get_world_data(world_index)
	var is_unlocked: bool = GameManager.is_world_unlocked(world_index)
	var world_stars: int = GameManager.get_world_stars(world_index)
	var max_world_stars: int = GameManager.LEVELS_PER_WORLD * 3
	
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	
	var style := StyleBoxFlat.new()
	style.bg_color = WORLD_COLORS[world_index] if is_unlocked else LOCKED_COLOR
	style.corner_radius_top_left = CARD_CORNER_RADIUS
	style.corner_radius_top_right = CARD_CORNER_RADIUS
	style.corner_radius_bottom_left = CARD_CORNER_RADIUS
	style.corner_radius_bottom_right = CARD_CORNER_RADIUS
	card.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	card.add_child(hbox)
	
	# Icon
	var icon_container := CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(icon_container)

	if is_unlocked and world_index < WORLD_ICON_PATHS.size():
		var icon_texture := TextureRect.new()
		icon_texture.texture = load(WORLD_ICON_PATHS[world_index])
		icon_texture.custom_minimum_size = WORLD_ICON_SIZE
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_container.add_child(icon_texture)
	else:
		var lock_label := Label.new()
		lock_label.text = "🔒"
		lock_label.add_theme_font_size_override("font_size", 40)
		icon_container.add_child(lock_label)
	
	# Info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label := Label.new()
	name_label.text = world_data.name if is_unlocked else "???"
	name_label.add_theme_font_size_override("font_size", 26)
	info_vbox.add_child(name_label)
	
	var desc_label := Label.new()
	if is_unlocked:
		desc_label.text = world_data.description
	else:
		var required_stars: int = world_index * GameManager.STARS_PER_WORLD_UNLOCK
		var current_stars: int = GameManager.get_total_stars()
		desc_label.text = "Need %d stars to unlock (%d/%d)" % [required_stars, current_stars, required_stars]
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	info_vbox.add_child(desc_label)
	
	# Star progress
	var progress_hbox := HBoxContainer.new()
	info_vbox.add_child(progress_hbox)
	
	var stars_count_label := Label.new()
	stars_count_label.text = " %d / %d" % [world_stars, max_world_stars]
	stars_count_label.add_theme_font_size_override("font_size", 14)
	stars_count_label.modulate = STAR_COLOR if is_unlocked else STAR_LOCKED_COLOR
	progress_hbox.add_child(stars_count_label)
	
	# Play button
	var play_btn := Button.new()
	play_btn.text = "▶" if is_unlocked else "🔒"
	play_btn.custom_minimum_size = Vector2(65, 80)
	play_btn.disabled = not is_unlocked
	if is_unlocked:
		play_btn.pressed.connect(_on_world_pressed.bind(world_index))
	hbox.add_child(play_btn)
	
	_worlds_container.add_child(card)
	
	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, CARD_SPACING)
	_worlds_container.add_child(spacer)

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_world_pressed(world_index: int) -> void:
	AudioManager.play_button()
	GameManager.go_to_level_select(world_index)


func _on_back_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_main_menu()


func _on_shop_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_shop()
