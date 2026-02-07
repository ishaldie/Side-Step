## ScreenEffects Autoload
## Provides screen shake, flash, and other visual feedback effects.
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const DEFAULT_SHAKE_DURATION: float = 0.25
const DEFAULT_SHAKE_INTENSITY: float = 6.0  # Reduced for less jarring effect
const SHAKE_DECAY_RATE: float = 8.0  # Faster decay for smoother feel

const FLASH_DURATION: float = 0.1

# =============================================================================
# STATE
# =============================================================================

var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO

var _current_camera: Camera2D

# =============================================================================
# LIFECYCLE
# =============================================================================

func _process(delta: float) -> void:
	_update_shake(delta)

# =============================================================================
# SCREEN SHAKE
# =============================================================================

## Triggers a screen shake effect
func shake(intensity: float = DEFAULT_SHAKE_INTENSITY, duration: float = DEFAULT_SHAKE_DURATION) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_find_camera()


## Small shake for minor impacts
func shake_small() -> void:
	shake(3.0, 0.1)


## Medium shake for hits
func shake_medium() -> void:
	shake(5.0, 0.2)


## Large shake for death/big impacts
func shake_large() -> void:
	shake(10.0, 0.3)


func _find_camera() -> void:
	# Try to find the current camera
	var viewport := get_viewport()
	if viewport:
		_current_camera = viewport.get_camera_2d()


func _update_shake(delta: float) -> void:
	if _shake_duration <= 0:
		_reset_camera()
		return
	
	_shake_duration -= delta
	
	# Apply random offset based on intensity
	var shake_offset := Vector2(
		randf_range(-_shake_intensity, _shake_intensity),
		randf_range(-_shake_intensity, _shake_intensity)
	)
	
	# Decay intensity over time
	_shake_intensity = maxf(_shake_intensity - SHAKE_DECAY_RATE * delta, 0.0)
	
	# Apply to camera if available
	if _current_camera:
		_current_camera.offset = _original_offset + shake_offset


func _reset_camera() -> void:
	if _current_camera:
		_current_camera.offset = _original_offset
	_shake_intensity = 0.0

# =============================================================================
# SCREEN FLASH
# =============================================================================

## Creates a flash effect (requires a ColorRect named "FlashOverlay" in the scene)
func flash(color: Color = Color.WHITE, duration: float = FLASH_DURATION) -> void:
	var flash_rect := _find_flash_overlay()
	if not flash_rect:
		return
	
	flash_rect.color = color
	flash_rect.visible = true
	
	var tween := create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, duration)
	tween.tween_callback(func(): flash_rect.visible = false)


func flash_white() -> void:
	flash(Color(1, 1, 1, 0.3), 0.08)  # Softer white flash


func flash_red() -> void:
	flash(Color(1, 0.2, 0.2, 0.2), 0.12)  # Softer red flash


func _find_flash_overlay() -> ColorRect:
	# Look for a flash overlay in the current scene
	var root := get_tree().current_scene
	if root and root.has_node("FlashOverlay"):
		return root.get_node("FlashOverlay") as ColorRect
	return null

# =============================================================================
# HITSTOP / FREEZE FRAME
# =============================================================================

## Briefly pauses the game for impact effect
func hitstop(duration: float = 0.05) -> void:
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	get_tree().paused = false

# =============================================================================
# SLOW MOTION
# =============================================================================

## Temporarily slows down time
func slow_motion(time_scale: float = 0.3, duration: float = 0.5) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0

# =============================================================================
# SCENE TRANSITIONS
# =============================================================================

## Transition duration for scene changes.
const TRANSITION_DURATION: float = 0.25

## Changes scene with a fade transition.
func transition_to_scene(scene_path: String) -> void:
	await fade_out(TRANSITION_DURATION)
	get_tree().change_scene_to_file(scene_path)
	await fade_in(TRANSITION_DURATION)


## Fades the screen to black (for scene transitions).
func fade_out(duration: float = 0.3) -> void:
	var overlay := _get_or_create_transition_overlay()
	if not overlay:
		return
	
	overlay.color = Color(0, 0, 0, 0)
	overlay.visible = true
	
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, duration)
	await tween.finished


## Fades the screen from black.
func fade_in(duration: float = 0.3) -> void:
	var overlay := _get_or_create_transition_overlay()
	if not overlay:
		return
	
	overlay.color = Color(0, 0, 0, 1)
	overlay.visible = true
	
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration)
	await tween.finished
	overlay.visible = false


func _get_or_create_transition_overlay() -> ColorRect:
	var canvas := get_node_or_null("/root/TransitionCanvas")
	if not canvas:
		canvas = CanvasLayer.new()
		canvas.name = "TransitionCanvas"
		canvas.layer = 100  # Above everything
		get_tree().root.add_child(canvas)
		
		var rect := ColorRect.new()
		rect.name = "Overlay"
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.color = Color(0, 0, 0, 0)
		rect.visible = false
		canvas.add_child(rect)
	
	return canvas.get_node("Overlay") as ColorRect
