## Shop Screen
## Allows players to purchase and equip footwear upgrades.
extends Control

# =============================================================================
# CONSTANTS
# =============================================================================

const CARD_SIZE: Vector2 = Vector2(400, 130)
const CARD_SPACING: float = 12.0
const CARD_CORNER_RADIUS: int = 10

const COLOR_EQUIPPED: Color = Color(0.2, 0.4, 0.3)
const COLOR_OWNED: Color = Color(0.25, 0.25, 0.3)
const COLOR_LOCKED: Color = Color(0.15, 0.15, 0.2)
const COLOR_DASH: Color = Color(0.3, 1, 0.5)
const COLOR_DOUBLE_JUMP: Color = Color(0.3, 0.7, 1)

const SHOE_ICONS: Array[Texture2D] = [
	preload("res://assets/sprites/shoes/barefoot.png"),
	preload("res://assets/sprites/shoes/flip_flops.png"),
	preload("res://assets/sprites/shoes/running_shoes.png"),
	preload("res://assets/sprites/shoes/winged_shoes.png")
]
const SHOE_ICON_SIZE: Vector2 = Vector2(55, 55)

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _shoes_container: VBoxContainer = $ScrollContainer/ShoesContainer
@onready var _coins_label: Label = $CoinsLabel
@onready var _current_shoe_label: Label = $CurrentShoeLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_update_display()
	_create_shoe_cards()


func _update_display() -> void:
	_coins_label.text = " %d" % GameManager.total_coins
	UIUtils.add_coin_icon(_coins_label)
	var shoe: Dictionary = GameManager.get_current_shoe_data()
	_current_shoe_label.text = "Equipped: %s %s" % [shoe.icon, shoe.name]


func _create_shoe_cards() -> void:
	for child in _shoes_container.get_children():
		child.queue_free()
	
	for i in range(GameManager.SHOES.size()):
		_create_shoe_card(i)


func _create_shoe_card(shoe_index: int) -> void:
	var shoe_data: Dictionary = GameManager.SHOES[shoe_index]
	var is_unlocked: bool = GameManager.unlocked_shoes[shoe_index]
	var is_equipped: bool = GameManager.current_shoe == shoe_index
	
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	
	var style := StyleBoxFlat.new()
	if is_equipped:
		style.bg_color = COLOR_EQUIPPED
	elif is_unlocked:
		style.bg_color = COLOR_OWNED
	else:
		style.bg_color = COLOR_LOCKED
	style.corner_radius_top_left = CARD_CORNER_RADIUS
	style.corner_radius_top_right = CARD_CORNER_RADIUS
	style.corner_radius_bottom_left = CARD_CORNER_RADIUS
	style.corner_radius_bottom_right = CARD_CORNER_RADIUS
	card.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var icon_texture := TextureRect.new()
	if shoe_index < SHOE_ICONS.size():
		icon_texture.texture = SHOE_ICONS[shoe_index]
	icon_texture.custom_minimum_size = SHOE_ICON_SIZE
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon_texture)
	
	var name_vbox := VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_vbox)
	
	var name_label := Label.new()
	name_label.text = shoe_data.name
	name_label.add_theme_font_size_override("font_size", 22)
	name_vbox.add_child(name_label)
	
	var desc_label := Label.new()
	desc_label.text = shoe_data.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	name_vbox.add_child(desc_label)
	
	# Stats
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 15)
	vbox.add_child(stats)
	
	var speed_label := Label.new()
	speed_label.text = "⚡ %d" % int(shoe_data.speed)
	speed_label.add_theme_font_size_override("font_size", 13)
	stats.add_child(speed_label)
	
	var jump_label := Label.new()
	jump_label.text = "⬆ %d" % int(shoe_data.jump_force)
	jump_label.add_theme_font_size_override("font_size", 13)
	stats.add_child(jump_label)
	
	if shoe_data.dash:
		var dash_label := Label.new()
		dash_label.text = "✓Dash"
		dash_label.add_theme_font_size_override("font_size", 12)
		dash_label.modulate = COLOR_DASH
		stats.add_child(dash_label)
	
	if shoe_data.double_jump:
		var dj_label := Label.new()
		dj_label.text = "✓2xJump"
		dj_label.add_theme_font_size_override("font_size", 12)
		dj_label.modulate = COLOR_DOUBLE_JUMP
		stats.add_child(dj_label)
	
	# Action button
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_container)
	
	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(110, 38)
	
	if is_equipped:
		action_btn.text = "EQUIPPED"
		action_btn.disabled = true
	elif is_unlocked:
		action_btn.text = "EQUIP"
		action_btn.pressed.connect(_on_equip_pressed.bind(shoe_index))
	else:
		var can_afford: bool = GameManager.can_afford_shoe(shoe_index)
		action_btn.text = "🪙 %d" % shoe_data.cost
		action_btn.disabled = not can_afford
		if can_afford:
			action_btn.pressed.connect(_on_buy_pressed.bind(shoe_index))
	
	btn_container.add_child(action_btn)
	_shoes_container.add_child(card)
	
	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, CARD_SPACING)
	_shoes_container.add_child(spacer)

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_buy_pressed(shoe_index: int) -> void:
	if GameManager.purchase_shoe(shoe_index):
		AudioManager.play_purchase()
		GameManager.equip_shoe(shoe_index)
		_update_display()
		_create_shoe_cards()


func _on_equip_pressed(shoe_index: int) -> void:
	GameManager.equip_shoe(shoe_index)
	AudioManager.play_equip()
	_update_display()
	_create_shoe_cards()


func _on_back_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_world_select()
