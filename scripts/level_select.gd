## Level Selection Screen
## Displays all levels within a world with their unlock/completion status.
extends Control

# =============================================================================
# CONSTANTS
# =============================================================================

const CARD_SIZE: Vector2 = Vector2(380, 80)
const CARD_SPACING: float = 4.0
const CARD_PADDING: int = 4
const CARD_CORNER_RADIUS: int = 10

const DIFFICULTY_EASY_MAX: float = 2.0
const DIFFICULTY_MEDIUM_MAX: float = 4.0

const COLOR_EASY: Color = Color(0.3, 0.9, 0.4)
const COLOR_MEDIUM: Color = Color(1, 0.8, 0.2)
const COLOR_HARD: Color = Color(1, 0.4, 0.3)
const COLOR_GOLD: Color = Color(1, 0.85, 0)
const COLOR_LOCKED: Color = Color(0.15, 0.15, 0.18)
const COLOR_UNLOCKED: Color = Color(0.25, 0.25, 0.3)
const COLOR_DESCRIPTION: Color = Color(0.65, 0.65, 0.65)
const COLOR_STAR_EMPTY: Color = Color(0.4, 0.4, 0.4)

const STAR_FILLED_TEX: Texture2D = preload("res://assets/sprites/ui/star_filled.png")
const STAR_EMPTY_TEX: Texture2D = preload("res://assets/sprites/ui/star_empty.png")

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _levels_container: VBoxContainer = $ScrollContainer/LevelsContainer
@onready var _coins_label: Label = $CoinsLabel
@onready var _world_label: Label = $WorldLabel
@onready var _world_icon: Label = $WorldIcon
@onready var _background: ColorRect = $Background

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	var world_data: Dictionary = GameManager.get_current_world_data()

	_coins_label.text = " %d" % GameManager.total_coins
	UIUtils.add_coin_icon(_coins_label, Vector2(18, 18), Vector2(-20, 2))
	_world_label.text = world_data.name
	_world_icon.text = world_data.icon
	_background.color = world_data.bg_color.darkened(0.3)

	_create_level_buttons()


func _create_level_buttons() -> void:
	for child in _levels_container.get_children():
		child.queue_free()

	_levels_container.add_theme_constant_override("separation", int(CARD_SPACING))

	for i in range(GameManager.LEVELS_PER_WORLD):
		_create_level_card(i)


func _create_level_card(level_index: int) -> void:
	var world_index: int = GameManager.current_world_index
	var world_data: Dictionary = GameManager.get_current_world_data()
	var level_data: Dictionary = world_data.levels[level_index]
	var is_unlocked: bool = GameManager.is_level_unlocked(world_index, level_index)
	var is_completed: bool = GameManager.levels_completed[world_index][level_index]
	var level_stars: int = GameManager.get_level_stars(world_index, level_index)
	
	var container := PanelContainer.new()
	container.custom_minimum_size = CARD_SIZE
	
	var style := StyleBoxFlat.new()
	if is_completed:
		style.bg_color = world_data.bg_color.lightened(0.1)
	elif is_unlocked:
		style.bg_color = COLOR_UNLOCKED
	else:
		style.bg_color = COLOR_LOCKED
	style.corner_radius_top_left = CARD_CORNER_RADIUS
	style.corner_radius_top_right = CARD_CORNER_RADIUS
	style.corner_radius_bottom_left = CARD_CORNER_RADIUS
	style.corner_radius_bottom_right = CARD_CORNER_RADIUS
	style.content_margin_top = CARD_PADDING
	style.content_margin_bottom = CARD_PADDING
	style.content_margin_left = CARD_PADDING
	style.content_margin_right = CARD_PADDING
	container.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	container.add_child(hbox)

	# Level number
	var num_label := Label.new()
	num_label.text = str(level_index + 1)
	num_label.add_theme_font_size_override("font_size", 24)
	num_label.custom_minimum_size = Vector2(32, 0)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(num_label)

	# Level info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = level_data.name if is_unlocked else "???"
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = level_data.description if is_unlocked else "Complete previous level"
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = COLOR_DESCRIPTION
	info_vbox.add_child(desc_label)

	# Stats row
	if is_unlocked:
		var stats_hbox := HBoxContainer.new()
		stats_hbox.add_theme_constant_override("separation", 10)
		info_vbox.add_child(stats_hbox)

		var diff_label := Label.new()
		diff_label.text = "⚡ %s" % level_data.difficulty
		diff_label.add_theme_font_size_override("font_size", 11)
		diff_label.modulate = _get_difficulty_color(level_data.difficulty)
		stats_hbox.add_child(diff_label)

		var distance_meters: int = int(level_data.target_distance / 100.0)
		var target_label := Label.new()
		target_label.text = "📏 %dm" % distance_meters
		target_label.add_theme_font_size_override("font_size", 11)
		stats_hbox.add_child(target_label)

	# Status / Play button with stars
	var btn_vbox := VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(btn_vbox)

	# Star display using custom star sprites
	var star_hbox := HBoxContainer.new()
	star_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var star_icon := TextureRect.new()
		if i < level_stars:
			star_icon.texture = STAR_FILLED_TEX
		else:
			star_icon.texture = STAR_EMPTY_TEX
		star_icon.custom_minimum_size = Vector2(18, 18)
		star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star_hbox.add_child(star_icon)
	btn_vbox.add_child(star_hbox)

	var play_btn := Button.new()
	play_btn.text = "▶" if is_unlocked else "🔒"
	play_btn.custom_minimum_size = Vector2(50, 32)
	play_btn.disabled = not is_unlocked
	if is_unlocked:
		play_btn.pressed.connect(_on_level_pressed.bind(level_index))
	btn_vbox.add_child(play_btn)
	
	_levels_container.add_child(container)


func _get_difficulty_color(difficulty: float) -> Color:
	if difficulty <= DIFFICULTY_EASY_MAX:
		return COLOR_EASY
	elif difficulty <= DIFFICULTY_MEDIUM_MAX:
		return COLOR_MEDIUM
	else:
		return COLOR_HARD

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_level_pressed(level_index: int) -> void:
	AudioManager.play_button()
	GameManager.start_level(GameManager.current_world_index, level_index)


func _on_back_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_world_select()


func _on_shop_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_shop()
