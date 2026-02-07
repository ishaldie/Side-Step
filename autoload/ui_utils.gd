## UIUtils Autoload
## Provides shared UI helper functions used across multiple scenes.
## Eliminates code duplication for common UI elements like icons.
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const COIN_ICON_PATH: String = "res://assets/sprites/ui/coin.png"
const STAR_ICON_PATH: String = "res://assets/sprites/ui/star_filled.png"
const STAR_EMPTY_ICON_PATH: String = "res://assets/sprites/ui/star_empty.png"

const DEFAULT_COIN_ICON_SIZE: Vector2 = Vector2(20, 20)
const DEFAULT_STAR_ICON_SIZE: Vector2 = Vector2(16, 16)

# =============================================================================
# PUBLIC API
# =============================================================================

## Adds a HUD coin icon to a label.
## Parameters:
##   label: The label to add the icon to
##   size: Optional custom size for the icon
##   offset: Optional custom position offset
func add_coin_icon(label: Label, size: Vector2 = DEFAULT_COIN_ICON_SIZE, offset: Vector2 = Vector2(-22, 0)) -> void:
	if label.has_node("CoinIcon"):
		return

	var icon := TextureRect.new()
	icon.name = "CoinIcon"
	icon.texture = load(COIN_ICON_PATH)
	if icon.texture:
		icon.custom_minimum_size = size
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = offset
		label.add_child(icon)


## Adds a star icon to a label.
## Parameters:
##   label: The label to add the icon to
##   size: Optional custom size for the icon
##   offset: Optional custom position offset
func add_star_icon(label: Label, size: Vector2 = DEFAULT_STAR_ICON_SIZE, offset: Vector2 = Vector2(-18, 2)) -> void:
	if label.has_node("StarIcon"):
		return

	var icon := TextureRect.new()
	icon.name = "StarIcon"
	icon.texture = load(STAR_ICON_PATH)
	if icon.texture:
		icon.custom_minimum_size = size
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = offset
		label.add_child(icon)


## Creates a styled panel container with rounded corners.
## Parameters:
##   bg_color: Background color for the panel
##   corner_radius: Corner radius (applied to all corners)
##   min_size: Minimum size for the panel
func create_styled_panel(bg_color: Color, corner_radius: int = 10, min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel := PanelContainer.new()
	if min_size != Vector2.ZERO:
		panel.custom_minimum_size = min_size

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	panel.add_theme_stylebox_override("panel", style)

	return panel
