## Tutorial Overlay
## Displays tutorial steps and contextual hints during gameplay.
extends CanvasLayer

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _dimmer: ColorRect = $Dimmer
@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/VBox/TitleLabel
@onready var _body_label: Label = $Panel/VBox/BodyLabel
@onready var _continue_button: Button = $Panel/VBox/ContinueButton
@onready var _skip_button: Button = $Panel/VBox/SkipButton
@onready var _hint_label: Label = $HintLabel

var _hint_tween: Tween = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Connect to tutorial manager signals
	TutorialManager.tutorial_step_changed.connect(_on_step_changed)
	TutorialManager.tutorial_completed.connect(_on_tutorial_completed)
	TutorialManager.show_hint.connect(_show_hint)
	
	# Start hidden
	_panel.visible = false
	_dimmer.visible = false
	_hint_label.visible = false
	
	# Check if we should show tutorial
	if TutorialManager.is_first_time():
		# Small delay before showing tutorial
		await get_tree().create_timer(0.5).timeout
		TutorialManager.start_tutorial()


func _on_step_changed(step: TutorialManager.TutorialStep) -> void:
	if step == TutorialManager.TutorialStep.NONE or step == TutorialManager.TutorialStep.COMPLETE:
		_panel.visible = false
		_dimmer.visible = false
		visible = false  # Hide entire overlay
		return
	
	var text_data: Dictionary = TutorialManager.get_step_text()
	_title_label.text = text_data.title
	_body_label.text = text_data.body
	_continue_button.text = text_data.button
	
	_show_panel()
	
	# Pause game during tutorial panels
	get_tree().paused = true


func _on_tutorial_completed() -> void:
	_panel.visible = false
	_dimmer.visible = false
	visible = false  # Hide entire overlay
	get_tree().paused = false


func _show_panel() -> void:
	_dimmer.visible = true
	_panel.visible = true
	
	# Animate in
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _hide_panel() -> void:
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		_panel.visible = false
		_dimmer.visible = false
	)


func _show_hint(hint_text: String, duration: float) -> void:
	# Cancel any existing hint animation
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	
	_hint_label.text = hint_text
	_hint_label.visible = true
	_hint_label.modulate.a = 0.0
	
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_label, "modulate:a", 1.0, 0.2)
	_hint_tween.tween_interval(duration)
	_hint_tween.tween_property(_hint_label, "modulate:a", 0.0, 0.3)
	_hint_tween.tween_callback(func(): _hint_label.visible = false)


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_continue_pressed() -> void:
	AudioManager.play_button()
	get_tree().paused = false
	TutorialManager.advance_step()


func _on_skip_pressed() -> void:
	AudioManager.play_button()
	get_tree().paused = false
	TutorialManager.skip_tutorial()
